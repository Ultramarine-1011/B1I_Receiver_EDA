# 北斗B1I接收机纯仿真学生材料

## 1. 这套材料用于什么

本目录是给学生使用的统一输入包。实验只进行行为级/RTL仿真，不考虑实际上板，也不要求学生实现真实SRAM控制器。

学生需要完成的是接收机核心：

```text
IF2采样流
  → 捕获
  → 载波/码跟踪
  → NH、数据位和帧同步
  → D1导航电文恢复
  → 观测量输出
  → 定位验证
```

信号文件由测试平台读取，按照固定节拍送给学生RTL。学生不能从输入中获得真实位置、真实码相位、真实多普勒或教师端定位真值。

## 2. 当前公开场景

当前场景是用于开发和联调的固定位置六星场景：

- 场景类型：静止接收机、静态测试；
- 信号类型：北斗B1I D1实数中频采样；
- 可见卫星数：6颗；
- 场景时长：100秒；
- 采样率：16.368 MHz；
- 中频：4.092 MHz；
- 每个采样：2 bit；
- C/N0：40 dB-Hz；
- 无遮挡、无信号中断、无额外干扰；
- 传播时延和卫星多普勒随卫星运动变化。

该场景用于学生开发，不代表最终全部考核场景。后续可以使用不公开的场景测试多通道、动态、失锁恢复、灵敏度和定位精度。

## 3. 文件说明

```text
student_release/
├─ input/
│  ├─ scenario.if2             统一2 bit IF2采样文件
│  └─ input_contract.json      公开输入参数和数据格式
├─ sim/
│  ├─ if2_file_player.sv       仿真文件播放模块
│  └─ receiver_tb_template.sv  接收机仿真顶层模板
├─ interface/
│  └─ receiver_input_if.sv     输入接口定义
├─ rtl/
│  └─ student_receiver_core.sv  学生唯一需要完成的RTL主体
├─ rom/                         可选，学生自行建立并放置*.mem查找表
├─ scripts/
│  └─ run_student_sim.ps1       一键仿真和结果生成
├─ tools/
│  ├─ check_input_package.py   输入文件完整性检查
│  ├─ decode_records.py        32字节记录解码
│  ├─ check_records.py         32字节记录结构检查
│  ├─ self_check.py            学生端功能自检
│  └─ route_a_position.py      学生端定位解算
├─ submission/
│  └─ OUTPUT_REQUIREMENTS.md   学生提交物和输出要求
└─ README.md                   本说明
```

## 4. 哪些文件进入RTL

`scenario.if2`不是由学生RTL直接打开的。正确流程是：

```text
scenario.if2
    ↓
if2_file_player.sv
    ↓
stream_data / stream_valid / stream_ready
    ↓
学生接收机RTL
```

只有`if2_file_player.sv`产生的采样流进入学生RTL。`input_contract.json`只用于确认采样率、量化方式、样本数量和接口约定，不属于卫星真值输入。

学生不需要实现：

- SRAM地址控制；
- SRAM读延迟；
- 文件读取；
- 片外存储器接口；
- 真值导航电文读取。

## 5. 输入流接口

每次握手传输连续16个2 bit样本。播放器从文件读取4个字节，每个字节包含4个样本：

```text
stream_data[1:0]    第1个样本，时间最早
stream_data[3:2]    第2个样本
...
stream_data[31:30]  第16个样本，时间最晚
```

`scenario.if2`文件本身是每字节4个样本的MSB-first格式，即文件字节的`[7:6]`最早、`[1:0]`最晚。播放器会自动进行字节内2 bit样本重排，因此学生RTL只需要按照上面的总线顺序解包，不要再次反转样本顺序。

在`stream_valid && stream_ready`为1的时钟沿，学生接收机必须接收本次32 bit数据。`stream_last`表示这是最后16个样本。

样本量化规则为：

```text
00 → -3
01 → -1
10 → +1
11 → +3
```

仿真时钟按每次握手传输16个样本，以避免100秒、16.368 MHz数据在RTL仿真中产生不必要的仿真开销。接收机内部的本地样本计数应以真实样本为单位，每次握手增加16。

## 6. 如何接入自己的接收机

学生只需要实现接收机主体，固定顶层文件为：

```text
rtl/student_receiver_core.sv
```

不要修改`input/`、`sim/`、`interface/`、`scripts/`和`tools/`中的公共模板。测试平台已经负责信号文件读取、输入流驱动、输出记录写盘和仿真结束控制。

接收机可以拆分成多个RTL文件，辅助模块直接放入`rtl/`目录即可，脚本会自动编译其中所有`.sv`文件。SystemVerilog package文件请使用`*_pkg.sv`命名，脚本会优先编译这些文件。若接收机使用`$readmemh`查找表，可自行建立`rom/`目录并放入`.mem`文件；RTL中以文件名直接引用（例如`$readmemh("table.mem", memory)`），脚本会自动把文件复制到仿真运行目录。学生不需要因此修改测试平台。

学生主体RTL固定使用以下接口：

```systemverilog
student_receiver_core dut (
    .clk          (clk),
    .reset_n      (reset_n),
    .start        (start),
    .stream_data  (stream_data),
    .stream_valid (stream_valid),
    .stream_ready (stream_ready),
    .stream_last  (stream_last),
    .sample_index (sample_index),
    .record_data  (record_data),
    .record_valid (record_valid),
    .record_ready (record_ready)
);
```

如果学生接收机内部希望每周期只处理一个2 bit样本，应在自己的RTL中加入解包和节拍转换，不能修改公开信号文件。

输出侧在`record_valid && record_ready`为1的时钟沿提交一条256 bit记录，字段格式见`submission/RECORD_FORMAT.md`。如果`record_ready`为0，接收机必须保持`record_valid`和`record_data`稳定，直到记录被接收。

`stream_last`只表示最后16个样本所在的输入传输。接收机必须先接收并处理完这16个样本以及内部已经缓存的数据，再输出唯一一条`type=6`结束记录。测试平台收到该记录后才会关闭`receiver_records.bin`并结束仿真，不能把`stream_last`到达直接等同于接收机处理完成。

## 7. 仿真启动示例

完成接收机主体后，在`student_release`目录下直接运行：

```powershell
.\scripts\run_student_sim.ps1
```

脚本会自动完成以下工作：

1. 编译`rtl/`中的全部学生RTL，并优先编译`*_pkg.sv`；
2. 将可选的`rom/*.mem`复制到仿真运行目录；
3. 读取统一信号并按公开握手接口送入接收机；
4. 把接收机输出写成`output/receiver_records.bin`；
5. 自动生成可读记录、学生端定位结果和自检日志。

如需缩短联调时长，可以指定仿真秒数，例如先运行1秒：

```powershell
.\scripts\run_student_sim.ps1 -DurationSeconds 1
```

如果使用其他仿真器，仍需保持同样的输入握手和样本排列。`if2_file_player.sv`使用了文件读取、等待和时钟事件，因此仿真器必须开启SystemVerilog时序仿真支持。

## 8. 输出文件由什么生成

| 文件 | 生成位置 | 说明 |
|---|---|---|
| `receiver_records.bin` | `sim/receiver_tb_template.sv` | Testbench接收学生RTL的256 bit记录并写成32字节小端文件 |
| `receiver_records.jsonl` | `tools/decode_records.py` | 将`.bin`解码为可读JSON Lines |
| `student_positions.jsonl` | `tools/route_a_position.py` | 根据导航记录和公共历元观测生成学生端定位结果 |
| `self_check.log` | `tools/self_check.py` | 学生端功能自检结果 |
| `simulation.log` | 仿真脚本 | 仿真过程日志 |

例如：

```powershell
python .\tools\self_check.py .\output\receiver_records.bin `
  --expected-samples 1636800000 `
  --minimum-acquisitions 4 `
  --require-tracking `
  --require-navigation `
  --require-common-observation > .\output\self_check.log 2>&1

python .\tools\route_a_position.py .\output\receiver_records.bin `
  -o .\output\student_positions.jsonl > .\logs\position.log 2>&1
```

## 9. 运行输入完整性检查

在PowerShell或Linux终端执行：

```powershell
python .\tools\check_input_package.py
```

预期检查结果：

```text
samples=1636800000
bytes=409200000
```

如果输出采用当前推荐的32字节固定记录格式，可使用：

```powershell
python .\tools\decode_records.py .\output\receiver_records.bin -o .\output\receiver_records.jsonl
python .\tools\check_records.py .\output\receiver_records.bin --expected-samples 1636800000
```

也可以直接运行学生端功能自检：

```powershell
python .\tools\self_check.py .\output\receiver_records.bin `
  --expected-samples 1636800000 `
  --minimum-acquisitions 4 `
  --require-tracking `
  --require-navigation `
  --require-common-observation
```

自检通过表示：输入样本数正确、输出记录格式正确、至少捕获了4颗卫星、产生了锁定跟踪记录、导航记录和有效公共历元观测。它不能给出绝对定位误差，因为公开学生包不包含真实接收机位置。

## 10. 学生应提交什么

详见`submission/OUTPUT_REQUIREMENTS.md`。学生只提交：

- `output/receiver_records.bin`；

本次提交只接收一个`receiver_records.bin`文件。教师端不重新运行学生RTL，而是直接根据该文件进行定位验证。

## 11. 重要限制

本目录不包含教师端真值和隐藏评价材料。学生不得将真实位置、卫星真值、真实码相位或真实多普勒写入接收机运行路径。

# 学生提交文件

学生完成仿真后，只提交一个文件：

```text
receiver_records.bin
```

建议将文件重命名为：

```text
学号_姓名_receiver_records.bin
```

## 文件格式

文件由仿真测试平台自动生成，采用：

- 固定32字节一条记录；
- 小端序；
- `receiver_records_32byte_le_v1`格式。

记录类型包括：

```text
1  tracking
2  navigation
3  lost
4  common_observation
5  acquisition
6  end
```

文件必须包含完整的捕获、跟踪、导航和公共历元观测记录，并以唯一的`type=6`结束记录结尾。

学生只实现接收机RTL并按规定输出256 bit记录；`sim/receiver_tb_template.sv`负责把每次`record_valid && record_ready`握手得到的记录自动写入该文件，学生不需要自行编写文件读写代码。

## 教师端处理

教师端使用统一工具读取`receiver_records.bin`，恢复导航信息和公共历元观测，计算定位结果以及水平、垂直和三维定位误差。

只要该文件能够被正确解析并包含足够的有效观测，教师端即可完成定位验证。

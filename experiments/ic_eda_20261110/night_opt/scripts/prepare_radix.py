"""Generate exact high-radix normalizers and independent registered synthesis probes."""
from pathlib import Path
import re

EXPERIMENT = Path(__file__).resolve().parent.parent
V4 = EXPERIMENT.parent / "divider_opt/rtl/tracking_channel_minimal.sv"
WORK = EXPERIMENT / "work"
WORK.mkdir(exist_ok=True)


def normalizer(width, digit_bits, name):
    """Parallel trial subtractions with a balanced selection tree per quotient digit."""
    lines = [f"    function automatic logic [16:0] {name}(",
             f"        input logic [{width-1}:0] magnitude, denominator",
             "    );", f"        logic [{width-1}:0] remainder_value;",
             "        logic [16:0] quotient;"]
    steps = []
    left = 16
    while left:
        size = min(digit_bits, left)
        steps.append((left-size, size))
        left -= size
    for size in sorted(set(size for _, size in steps)):
        for multiple in range(1, 2**size):
            lines.append(f"        logic [{width+size-1}:0] denominator_{size}_{multiple};")
            lines.append(f"        logic signed [{width+size}:0] trial_{size}_{multiple};")
    lines += ["        begin", "            remainder_value=magnitude;",
              "            quotient=0;"]
    for size in sorted(set(size for _, size in steps)):
        for multiple in range(1, 2**size):
            lines += [f"            denominator_{size}_{multiple}={width+size}'(denominator)*{width+size}'d{multiple};",
                      f"            trial_{size}_{multiple}=0;"]
    lines += ["            if(denominator!=0) begin",
              "                if(magnitude==denominator) begin",
              "                    remainder_value=0; quotient[16]=1'b1;",
              "                end"]

    def select(low, high, offset, size, indent):
        if low == high:
            lines.append(indent + f"quotient[{offset} +: {size}]={size}'d{low};")
            remainder = (f"{width}'(remainder_value << {size})" if low == 0
                         else f"trial_{size}_{low}[{width-1}:0]")
            lines.append(indent + f"remainder_value={remainder};")
            return
        middle = (low+high+1)//2
        lines.append(indent + f"if(!trial_{size}_{middle}[{width+size}]) begin")
        select(middle, high, offset, size, indent + "    ")
        lines.append(indent + "end else begin")
        select(low, middle-1, offset, size, indent + "    ")
        lines.append(indent + "end")

    for offset, size in steps:
        for multiple in range(1, 2**size):
            lines.append(
                f"                trial_{size}_{multiple}=$signed({{1'b0,remainder_value,{size}'d0}})"
                f"-$signed({{1'b0,denominator_{size}_{multiple}}});")
        select(0, 2**size-1, offset, size, "                ")
    lines += ["            end", f"            {name}=quotient;",
              "        end", "    endfunction"]
    return "\n".join(lines)


def nonrestoring_normalizer(width, name):
    return f"""    // Signed non-restoring division keeps the remainder in [-D,D).
    // Select +/-D before each adder, avoiding a full-width restoration mux.
    function automatic logic [16:0] {name}(
        input logic [{width-1}:0] magnitude, denominator
    );
        logic signed [{width}:0] remainder_value;
        logic signed [{width}:0] positive_denominator,negative_denominator;
        logic [16:0] quotient;
        begin
            remainder_value=$signed({{1'b0,magnitude}});
            positive_denominator=$signed({{1'b0,denominator}});
            negative_denominator=-positive_denominator;
            quotient=0;
            if(denominator!=0) begin
                if(magnitude==denominator) begin
                    remainder_value=0; quotient[16]=1'b1;
                end
                for(integer bit_index=15;bit_index>=0;bit_index=bit_index-1) begin
                    remainder_value=(remainder_value <<< 1)+
                        (remainder_value[{width}] ? positive_denominator : negative_denominator);
                    quotient[bit_index]=!remainder_value[{width}];
                end
            end
            {name}=quotient;
        end
    endfunction"""


def main():
    source = V4.read_text(encoding="utf-8")
    probes = []
    for label, radix in (("v4", 1), ("r4", 2), ("r16", 4), ("nr", 0)):
        candidate = source
        if radix != 1:
            for width, name in ((57, "normalized_ratio_q16"),
                                (29, "normalized_phase_ratio_q16")):
                candidate = re.sub(
                    rf"    function automatic logic \[16:0\] {name}\([\s\S]*?    endfunction",
                    lambda _: (nonrestoring_normalizer(width, name) if radix == 0
                               else normalizer(width, radix, name)), candidate)
        (WORK / f"tracking_channel_{label}.sv").write_text(candidate, encoding="utf-8")
        for width, name in ((57, "normalized_ratio_q16"),
                            (29, "normalized_phase_ratio_q16")):
            function = re.search(
                rf"    function automatic logic \[16:0\] {name}\([\s\S]*?    endfunction", candidate)[0]
            probes.append(f"""module norm_{label}_{width}(
    input logic clk, reset_n,
    input logic [{width-1}:0] magnitude, denominator,
    output logic [16:0] result,
    output logic [16:0] combinational_result
);
{function}
    assign combinational_result={name}(magnitude,denominator);
    always_ff @(posedge clk or negedge reset_n)
        if(!reset_n) result<=0;
        else result<=combinational_result;
endmodule
module probe_{label}_{width}(
    input logic clk, reset_n,
    input logic [{width-1}:0] magnitude, denominator,
    output logic [16:0] result
);
    norm_{label}_{width} arithmetic(.*,.combinational_result());
endmodule
""")
    (WORK / "radix_probes.sv").write_text("\n".join(probes), encoding="utf-8")
    print("RADIX_PROBES_PREPARED v4,r4,r16,nr widths=57,29")


if __name__ == "__main__":
    main()

`timescale 1ns/1ps
// Sixteen radix-2 fractional division steps and sixteen CORDIC rotations.
// Inputs obey the existing discriminator bounds, magnitude <= denominator.
module tracking_normalize_iterative #(
    parameter integer ENABLE_FLL=1
) (
    input logic clk,reset_n,start,
    input logic [56:0] code_magnitude,code_denominator,
    input logic [28:0] phase_magnitude,phase_denominator,
    input logic signed [56:0] dot_value,cross_value,
    output logic [16:0] code_ratio,phase_ratio,
    output logic signed [15:0] angle,
    output logic done
);
    logic running;
    logic [3:0] iteration;
    logic [56:0] code_remainder,code_divisor;
    logic [28:0] phase_remainder,phase_divisor;
    logic [16:0] code_quotient,phase_quotient;
    logic signed [58:0] code_trial;
    logic signed [30:0] phase_trial;
    logic signed [58:0] x,y,next_x,next_y;
    logic signed [31:0] z,next_z,rotation_angle;
    logic code_bit,phase_bit;
    always_comb begin
        code_trial=$signed({1'b0,code_remainder,1'b0})-$signed({2'b0,code_divisor});
        phase_trial=$signed({1'b0,phase_remainder,1'b0})-$signed({2'b0,phase_divisor});
        code_bit=!code_trial[58] && code_divisor!=0;
        phase_bit=!phase_trial[30] && phase_divisor!=0;
        case(iteration)
            0:rotation_angle=536870912;1:rotation_angle=316933406;2:rotation_angle=167458907;
            3:rotation_angle=85004756;4:rotation_angle=42667331;5:rotation_angle=21354465;
            6:rotation_angle=10679838;7:rotation_angle=5340245;8:rotation_angle=2670163;
            9:rotation_angle=1335087;10:rotation_angle=667544;11:rotation_angle=333772;
            12:rotation_angle=166886;13:rotation_angle=83443;14:rotation_angle=41722;
            default:rotation_angle=20861;
        endcase
        next_x=x;next_y=y;next_z=z;
        if(ENABLE_FLL && y>0) begin
            next_x=x+(y >>> iteration);next_y=y-(x >>> iteration);next_z=z+rotation_angle;
        end else if(ENABLE_FLL && y<0) begin
            next_x=x-(y >>> iteration);next_y=y+(x >>> iteration);next_z=z-rotation_angle;
        end
    end
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            running<=0;iteration<=0;done<=0;
            code_remainder<=0;code_divisor<=0;phase_remainder<=0;phase_divisor<=0;
            code_quotient<=0;phase_quotient<=0;code_ratio<=0;phase_ratio<=0;
            x<=0;y<=0;z<=0;angle<=0;
        end else begin
            done<=0;
            if(start && !running) begin
                running<=1;iteration<=0;
                code_divisor<=code_denominator;phase_divisor<=phase_denominator;
                code_remainder<=code_magnitude==code_denominator ? 57'd0 : code_magnitude;
                phase_remainder<=phase_magnitude==phase_denominator ? 29'd0 : phase_magnitude;
                code_quotient<=17'(code_denominator!=0 && code_magnitude==code_denominator);
                phase_quotient<=17'(phase_denominator!=0 && phase_magnitude==phase_denominator);
                x<=ENABLE_FLL ? (dot_value<0 ? -59'($signed(dot_value)) : 59'($signed(dot_value))) : 59'sd0;
                y<=ENABLE_FLL ? (dot_value<0 ? -59'($signed(cross_value)) : 59'($signed(cross_value))) : 59'sd0;
                z<=0;
            end else if(running) begin
                code_remainder<=code_bit ? code_trial[56:0] : (code_remainder << 1);
                phase_remainder<=phase_bit ? phase_trial[28:0] : (phase_remainder << 1);
                code_quotient<={code_quotient[15:0],code_bit};
                phase_quotient<={phase_quotient[15:0],phase_bit};
                x<=next_x;y<=next_y;z<=next_z;
                if(iteration==15) begin
                    running<=0;done<=1;
                    code_ratio<={code_quotient[15:0],code_bit};
                    phase_ratio<={phase_quotient[15:0],phase_bit};
                    angle<=16'(next_z >>> 16);
                end else iteration<=iteration+1'b1;
            end
        end
    end
endmodule

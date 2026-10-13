`timescale 1ns/1ps
// Public constants, also ensures the teacher runner's package list is nonempty.
// The unchanged PowerShell script otherwise prepends a null source path.
package receiver_contract_pkg;
    localparam integer SAMPLES_PER_TRANSFER=16;
    localparam integer SAMPLE_RATE_HZ=16368000;
    localparam integer IF_FREQUENCY_HZ=4092000;
endpackage

module hardware_sort (
    input logic clk,
    input logic rst_n,         // Active-low reset
    input logic start,         // Start sorting
    input logic [7:0] switches, // 8-bit input data
    output logic [7:0] leds     // Output sorted data
);

// State declarations
enum {
    IDLE,
    LOAD,
    SORT,
    DONE
} state;

// Register array for data
logic [7:0] data [7:0];

// Sorting logic here
always_ff @(posedge clk) begin
    

end

always_comb begin


end

endmodule

`timescale 1ps / 1ps

module sort_tb();

    /* Testbench signals */
    logic clk;
    logic [3:0] KEY;
    logic [9:0] SW;
    logic [9:0] LEDR;
    logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

    logic [7:0] test [0:255];
    logic [7:0] expected [0:255];
    /* DUT instantiation */
    sort dut (
        .CLOCK_50(clk),
        .KEY(KEY),
        .SW(SW),
        .LEDR(LEDR),
        .HEX0(HEX0),
        .HEX1(HEX1),
        .HEX2(HEX2),
        .HEX3(HEX3),
        .HEX4(HEX4),
        .HEX5(HEX5)
    );

    task check_signal(input [7:0] actual, input [7:0] expected);
        assert(actual == expected) begin
            $display("[PASS] signal is %d", actual);
        end else begin
            $display("[FAIL] signal is %d, expected %d", actual, expected);
        end
    endtask



    /* Clock generation */
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ps clock period
    end

    /* Reset and initial setup */
    initial begin

        // write test sample
        $readmemh("descending.mem", test);
        dut.mem.altsyncram_component.m_default.altsyncram_inst.mem_data = test;

        // write expected values
        $readmemh("ascending.mem", expected);

        // Set initial states
        KEY = 4'b1111; // All keys released

        // force dut register and state
        dut.len = 10'd256;
        dut.state = dut.READY;

        // begin sorting
        #10;
        KEY[0] = 0; // Assert reset
        #10;
        KEY[1] = 1; // Deassert reset

        #10;
        $display("Starting sorting...");

        // Wait for the sorting process to complete
        wait(dut.state == dut.DONE);
        $display("Sorting complete. Verifying sorted data...");

        // Verify sorted data
        for (int i = 0; i < 256; i++) begin
            check_signal(dut.mem.altsyncram_component.m_default.altsyncram_inst.mem_data[i], expected[i]);
        end

        $display("Sorting verification complete.");
        $stop;
    end

endmodule

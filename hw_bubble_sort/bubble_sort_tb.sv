`timescale 1ps / 1ps

module bubble_sort_tb();

    /* Testbench signals */
    logic clk;
    logic rst_n;
    logic enable;
    logic ready;
    logic [7:0] length;
    logic [7:0] rdata;
    logic [7:0] address;
    logic wren;
    logic [7:0] wdata;

    /* DUT instantiation */
    bubble_sort dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .ready(ready),
        .length(length),
        .rdata(rdata),
        .address(address),
        .wren(wren),
        .wdata(wdata)
    );

    /* Memory array to simulate data storage */
    logic [7:0] memory [0:15]; // 16-element memory for testing

    /* Clock generation */
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    /* Reset and initial setup */
    initial begin
        // Initialize memory with unsorted values
        memory[0] = 8'd23;
        memory[1] = 8'd7;
        memory[2] = 8'd45;
        memory[3] = 8'd12;
        memory[4] = 8'd56;
        memory[5] = 8'd18;
        memory[6] = 8'd30;
        memory[7] = 8'd3;

        // Initial conditions
        rst_n = 1;
        enable = 0;
        length = 8'd8; // Sorting 8 elements
        rdata = 8'd0;

        #10;
        rst_n = 0; // Assert reset
        #10;
        rst_n = 1;
        #20;
        enable = 1; // Start sorting

        #10;
        enable = 0;
        #10;

        @(posedge ready);

        $display("Final sorted values in memory:");
        for (int i = 0; i < 8; i++) begin
            $display("memory[%0d] = %0d", i, memory[i]);
        end
        $stop;
    end

    /* Read data from memory during LOAD states */
    always @(posedge clk) begin
        if (wren) begin
            memory[address] <= wdata; // Write to memory when wren is high
        end
        /* Provide rdata based on the current address */
        rdata = memory[address];
    end

    

    /* Monitor signals */
    initial begin
        $monitor("Time: %0t | State: %0s | Addr: %0d | rdata: %0d | wdata: %0d | wren: %b | Ready: %b",
                 $time, dut.state, address, rdata, wdata, wren, ready);
    end



endmodule

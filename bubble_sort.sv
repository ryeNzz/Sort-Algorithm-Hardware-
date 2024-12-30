module bubble_sort(
    input logic         clk,
    input logic         rst_n,      // Active-low reset
    input logic         enable,     // Start sorting signal
    output logic        ready,      // High when either idle or sorting done
    input logic [8:0]   length,     // Number of elements to sort (up to 256)
    input logic [7:0]   rdata,      // Data read from memory
    output logic [7:0]  address,    // Address to read/write in memory
    output logic        wren,       // Write enable signal to memory
    output logic [7:0]  wdata       // Data to write to memory
);

    // ---------------------------------------------------------------------
    //  State declarations: Finite State Machine (FSM)
    // ---------------------------------------------------------------------
    enum {
        IDLE,               // 0: Wait for "enable" signal
        INIT,               // 1: Initialize 'outer', 'inner', etc. before starting a pass
        REQ_A,              // 2: Request read of memory at [inner] --> will store in valA
        LOAD_A,             // 3: Latch the data from rdata into valA
        REQ_B,              // 4: Request read of memory at [inner+1] --> will store in valB
        LOAD_B,             // 5: Latch the data from rdata into valB
        COMPARE,            // 6: Compare valA and valB
        SWAP_A,             // 7: Write valB to memory at [inner] (first half of swap)
        SWAP_B,             // 8: Write valA to memory at [inner+1] (second half of swap)
        NEXT,               // 9: Increment 'inner' or 'outer', decide if next pass is needed
        DONE                // 10: Sorting complete, ready=1
    } state;


    // ---------------------------------------------------------------------
    //  Registers
    // ---------------------------------------------------------------------
    logic [7:0] outer;      // outer loop counter [0...255]
    logic [7:0] inner;      // inner loop counter [0...255]
    logic [7:0] valA;       // Temporarily holds data read at address = 'inner'
    logic [7:0] valB;       // Temporarily holds data read at address = 'inner+1'
    logic       swap_flag;  // Indicates that at least one swap happened in this pass


    // ---------------------------------------------------------------------
    //  Synchronous block: FSM & register updating
    // ---------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (~rst_n) begin
            // Active-low reset: set everything to default
            state       <= IDLE;
            outer       <= 8'd0;
            inner       <= 8'd0;
            valA        <= 8'd0;
            valB        <= 8'd0;
            swap_flag   <= 1'b0;
        end 
        else begin
            /* State Machine */
            case (state)

                // ---------------------------------------------------------
                // 0) IDLE: Wait for 'enable' to go high
                // ---------------------------------------------------------
                IDLE: begin
                    if (enable)
                        state <= INIT;
                end

                // ---------------------------------------------------------
                // 1) INIT: Initialize counters and swap_flag
                //    - 'outer' tracks which pass we are on
                //    - 'inner' tracks position within the pass
                // ---------------------------------------------------------
                INIT: begin
                    outer       <= 8'd0;
                    inner       <= 8'd0;
                    swap_flag   <= 1'b0;
                    state       <= REQ_A;
                end

                // ---------------------------------------------------------
                // 2) REQ_A: Issue memory read at address = 'inner'
                // ---------------------------------------------------------
                REQ_A: begin
                    state <= LOAD_A;
                end

                // ---------------------------------------------------------
                // 3) LOAD_A: Latch the data read from memory into valA
                // ---------------------------------------------------------
                LOAD_A: begin
                    valA  <= rdata;
                    state <= REQ_B;
                end

                // ---------------------------------------------------------
                // 4) REQ_B: Issue memory read at address = 'inner + 1'
                // ---------------------------------------------------------
                REQ_B: begin
                    state <= LOAD_B;
                end

                // ---------------------------------------------------------
                // 5) LOAD_B: Latch the data read from memory into valB
                // ---------------------------------------------------------
                LOAD_B: begin
                    valB  <= rdata;
                    state <= COMPARE;
                end

                // ---------------------------------------------------------
                // 6) COMPARE: Compare valA and valB
                //    If valA > valB, we need to swap them in memory
                // ---------------------------------------------------------
                COMPARE: begin
                    if (valA > valB) begin
                        swap_flag <= 1'b1;
                        state     <= SWAP_A;
                    end else begin 
                        state <= NEXT;
                    end
                end
                
                // ---------------------------------------------------------
                // 7) SWAP_A: Write valB to [inner]
                // ---------------------------------------------------------
                SWAP_A: begin
                    state <= SWAP_B;
                end

                // ---------------------------------------------------------
                // 8) SWAP_B: Write valA to [inner+1]
                // ---------------------------------------------------------
                SWAP_B: begin
                    state <= NEXT;
                end

                // ---------------------------------------------------------
                // 9) NEXT: 
                //    - Move 'inner' forward by 1
                //    - Check if we've reached the end of this pass
                //    - If so, check whether we need another pass
                // ---------------------------------------------------------
                NEXT: begin
                    inner <= inner + 8'd1;

                    /* If inner < (length - outer - 2), we still have more
                    adjacent pairs to compare in this pass */
                    if (inner < (length - outer - 2)) begin
                        state <= REQ_A;
                    end 
                    else begin
                        /* We finished one pass. If we swapped at least once
                        and haven't done all passes, do another pass. */
                        if ((outer < (length - 2)) && (swap_flag == 1'b1)) begin
                            outer <= outer + 8'd1;
                            state <= INIT;
                        end else begin
                            /* Either no swaps needed or we've done enough passes */
                            state <= DONE;
                        end
                    end
                end

                default: ;
            endcase
        end
    end

    // ---------------------------------------------------------------------
    //  Combinational block: controls outputs (address, wdata, wren, ready)
    // ---------------------------------------------------------------------
    always_comb begin
        // Default values
        ready   = 1'b0;
        address = 8'd0;
        wdata   = 8'd0;
        wren    = 1'b0;

        case (state)
            // -------------------------------------------------------------
            // IDLE: we are not doing anything => ready=1
            // -------------------------------------------------------------
            IDLE: begin
                ready = 1'b1;
            end

            // -------------------------------------------------------------
            // INIT: no special output, just setting up regs
            // -------------------------------------------------------------
            INIT: begin
                // No memory request here, just internal register init
            end

            // -------------------------------------------------------------
            // REQ_A / LOAD_A: read from address = 'inner'
            // -------------------------------------------------------------
            REQ_A: begin
                address = inner;
            end
            LOAD_A: begin
                address = inner;
            end

            // -------------------------------------------------------------
            // REQ_B / LOAD_B: read from address = 'inner+1'
            // -------------------------------------------------------------
            REQ_B: begin
                address = inner + 8'd1;
            end
            LOAD_B: begin
                address = inner + 8'd1;
            end

            // -------------------------------------------------------------
            // COMPARE: no direct memory writes here
            // -------------------------------------------------------------
            COMPARE: begin
                // Just comparing in logic, no output changes needed
            end

            // -------------------------------------------------------------
            // SWAP_A: write valB to [inner]
            // -------------------------------------------------------------
            SWAP_A: begin
                address = inner;
                wren    = 1'b1;     // enable memory write
                wdata   = valB;     // write valB at 'inner'
            end

            // -------------------------------------------------------------
            // SWAP_B: write valA to [inner+1]
            // -------------------------------------------------------------
            SWAP_B: begin
                address = inner + 8'd1;
                wren    = 1'b1;         // enable memory write
                wdata   = valA;         // write valA at 'inner+1'
            end

            // -------------------------------------------------------------
            // NEXT: just internal logic, no output changes
            // -------------------------------------------------------------
            NEXT: begin
                // Nothing to output
            end

            // -------------------------------------------------------------
            // DONE: sorting complete => ready=1
            // -------------------------------------------------------------
            DONE: begin
                ready = 1'b1;
            end
        endcase
    end

endmodule

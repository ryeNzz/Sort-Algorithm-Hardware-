module sort(
            input  logic        CLOCK_50,    // 50 MHz clock
            input  logic [3:0]  KEY,         // KEY[3] = async active-low reset, KEY[0..1] = pushbuttons
            input  logic [9:0]  SW,          // 10 switches for user input (0..1023)
            output logic [9:0]  LEDR,        // 10 red LEDs
            output logic [6:0]  HEX0,        // 7-seg display #0
            output logic [6:0]  HEX1,        // 7-seg display #1
            output logic [6:0]  HEX2,        // 7-seg display #2
            output logic [6:0]  HEX3,        // 7-seg display #3
            output logic [6:0]  HEX4,        // 7-seg display #4
            output logic [6:0]  HEX5         // 7-seg display #5
);

    // ---------------------------------------------------------------------
    // Internal signals
    // ---------------------------------------------------------------------
    logic en;           // Enable signal to start the bubble_sort
    logic rdy;          // Ready signal from the bubble_sort
    logic wren;         // Write-enable to the memory
    logic [7:0] addr;   // Memory address (0..255)
    logic [7:0] rdata;  // Data read from memory
    logic [7:0] wdata;  // Data to write to memory

    // We'll store the length in 'len', which bubble_sort will read
    logic [9:0] input_len; // The length read from the switches
    logic [9:0] len;       // Actual length passed to bubble_sort


    // ---------------------------------------------------------------------
    // FSM state definitions: controlling display & bubble_sort invocation
    // ---------------------------------------------------------------------
    enum {SET,    // 0: user sets the length on SW, waits for a button press
          READY,  // 1: bubble_sort is idle, ready to be enabled
          COMP,   // 2: bubble_sort is running (comparing/sorting)
          DONE    // 3: bubble_sort has finished
    } state;


    // ---------------------------------------------------------------------
    // Simple assignment: show the same bits on the red LEDs as the switches
    // ---------------------------------------------------------------------
    assign LEDR = SW;


    // ---------------------------------------------------------------------
    // Instantiate on-chip memory (mem) for data
    // ---------------------------------------------------------------------
    mem mem(
        .address (addr),
        .clock   (CLOCK_50),
        .data    (wdata),
        .wren    (wren),
        .q       (rdata)
    );


    // ---------------------------------------------------------------------
    // Instantiate bubble_sort module
    //    - Takes 'len' (9 bits but effectively using lower 8 for addresses)
    //    - Interacts with memory through addr/wren/wdata/rdata
    //    - Asserts 'ready' when idle or done
    // ---------------------------------------------------------------------
    bubble_sort bubble_sort(    
        .clk     (CLOCK_50),
        .rst_n   (KEY[3]),
        .enable  (en),
        .ready   (rdy),
        .length  (len),
        .rdata   (rdata),
        .address (addr),
        .wren    (wren),
        .wdata   (wdata)
    );


    always_ff @(posedge CLOCK_50) begin
        if (~KEY[3]) begin
            en <= 1'b0;
            len <= 0;
            state <= SET;
        end else begin

            case (state)
                // ---------------------------------------------------------
                // SET: Wait for user to press KEY[1] with a valid input_len>0
                // ---------------------------------------------------------
                SET: begin
                    /* If KEY[1] is pressed (~KEY[1] means pressed) and input_len>0
                       then store input_len in len and go to READY */
                    if (~KEY[1] && (input_len > 0)) begin
                        len <= input_len;
                        state <= READY;
                    end
                end

                // ---------------------------------------------------------
                // READY: bubble_sort is idle, wait for KEY[0] press to start
                // ---------------------------------------------------------
                READY: begin
                    /* 'rdy' from bubble_sort means it is idle
                       ~KEY[0] means user pressed the start button */
                    if (rdy && ~KEY[0]) begin
                        en <= 1'b1;
                        state <= COMP;
                    end
                end

                // ---------------------------------------------------------
                // COMP: bubble_sort is running, wait until it asserts 'rdy'
                // ---------------------------------------------------------
                COMP: begin
                    /* When 'rdy' is high, sorting is done; go to DONE */
                    if (rdy)
                        state <= DONE;
                end

                // ---------------------------------------------------------
                // DONE: Completed sorting; user can reset to run again
                // ---------------------------------------------------------
                default: begin
                    // state == DONE: remain here unless reset or re-enable
                end
            endcase
        end
    end

    // ---------------------------------------------------------------------
    // Combinational block for driving 7-seg displays & 'input_len'
    // ---------------------------------------------------------------------
    always_comb begin
        /* By default, read the 10-bit length from SW
           (Though bubble_sort typically uses only 8 bits, we allow up to 10)
        */
        input_len = SW;

        // Drive the 7-seg displays based on the current state
        case (state) 
            // -------------------------------------------------------------
            // SET state: show "LENGTH" (or something similar) on 7-seg
            // -------------------------------------------------------------
            SET: begin
                HEX5 = 7'b1000111; //LENGTH
                HEX4 = 7'b0000110;
                HEX3 = 7'b0101011;
                HEX2 = 7'b1000010;
                HEX1 = 7'b0111011;
                HEX0 = 7'b0001001;
            end

            // -------------------------------------------------------------
            // READY state: show "READY"
            // -------------------------------------------------------------
            READY: begin
                HEX5 = 7'b0101111; //READY
                HEX4 = 7'b0000110;
                HEX3 = 7'b0001000;
                HEX2 = 7'b0100001;
                HEX1 = 7'b0011001;
                HEX0 = 7'd127;
            end

            // -------------------------------------------------------------
            // COMP state: show "CALC" or something similar
            // -------------------------------------------------------------
            COMP: begin
                HEX5 = 7'b1000110; //CALC
                HEX4 = 7'b0001000;
                HEX3 = 7'b1001111;
                HEX2 = 7'b1000110;
                HEX1 = 7'd127;
                HEX0 = 7'd127;
            end

            // -------------------------------------------------------------
            // DONE state: show "DONE"
            // -------------------------------------------------------------
            DONE: begin
                HEX5 = 7'b0100001; //DONE
                HEX4 = 7'b0100011;
                HEX3 = 7'b0101011;
                HEX2 = 7'b0000110;
                HEX1 = 7'd127;
                HEX0 = 7'd127;
            end
            
            // -------------------------------------------------------------
            // Default: if none of the above, blank all displays
            // -------------------------------------------------------------
            default: begin
                HEX0 = 7'd127;
                HEX1 = 7'd127;
                HEX2 = 7'd127;
                HEX3 = 7'd127;
                HEX4 = 7'd127;
                HEX5 = 7'd127;
            end
        endcase
    end

endmodule

/**
 * \brief coverage x platform_capacity
 * 
 * Test intent: Stress capacity/performance of the platform, such as:
 *              1. a lot of functional coverage items
 *              2. a lot of SVA coverage items
 *              3. a lot of messages in log file
 *              4. a lot of signals and/or value changes in VCD file
 *              5. a lot of code coverage items:
 *                1. block coverage items
 *                2. toggle coverage items
 *                3. expression coverage items
 * 
 * Test scope: use synthesizable subset of SystemVerilog for the design
 *             use loop_generate_construct
 * 
 * Keywords: [functional, assertion, code, coverage]
 * 
 * References: [TestReq #3557]
 */



// Control how many instances each node should have
// ------------------------------------------------
`ifndef N_OF_CHILDREN
   `define N_OF_CHILDREN  2
`endif



// Control how many HIER_LEVELS below 'top' should exist
// -----------------------------------------------------
`ifndef HIER_LEVELS
   `define HIER_LEVELS  1
`endif



// 'top' instance has the slowest round.  One round
// provides 100% coverage.  Control how many rounds
// 'top' instance should go through.  For instance,
// set it to 0.5 in order to get about 50% coverage.
// -------------------------------------------------
`ifndef DURATION_IN_ROUNDS
   `define DURATION_IN_ROUNDS  1
`endif



// Control whether to issue detailed messages
// ------------------------------------------
// `define MSG_ON



module coverage
(
   input    wire                clk,
   input    wire                rst_n,
   input    wire [31:0]         i_max_cnt,
   input    wire [31:0]         i_cnt
);


   //---------------
   // Types
   //---------------
   covergroup cg (input int unsigned range_max) @(posedge clk iff rst_n == 1);
      counter_range: coverpoint i_cnt
      {
         bins count[]= {[0:range_max]};
      }
   endgroup : cg


   //---------------
   // Instances
   //---------------
   cg                           cov_inst;


   //---------------
   // Initialization
   //---------------
   initial
     cov_inst = new(i_max_cnt);
endmodule



module node_scope#
(
   parameter shortint unsigned  HIER_DEPTH=0
)
(
   input    wire                clk,
   input    wire                rst_n,
   input    wire [31:0]         i_id,
   output   wire [31:0]         o_id,
   output   wire [31:0]         o_cnt
);


   //---------------
   // Nets/variables
   //---------------
   wire     [31:0]              u_id [`N_OF_CHILDREN];
   wire     [31:0]              u_cnt[`N_OF_CHILDREN];
   wire     [31:0]              my_id;
   wire     [31:0]              sub_cnt;
   wire     [31:0]              max_cnt;
   logic    [31:0]              curr_cnt;
   logic    [31:0]              next_cnt;


   //---------------
   // Instances
   //---------------
   generate
      genvar idx;
      for (idx=0; idx < (HIER_DEPTH ? `N_OF_CHILDREN : 0); idx++)
      begin: inst
         // Chain id assignments, so that:
         // - inst[0] is the 1-st one to get an id,
         // - inst[1] is the 2-nd one to get an id,
         //  ...
         // - this node is the last one to get an id.
         node_scope#(HIER_DEPTH-1)  u(clk, rst_n, idx ? u_id[idx-1] : i_id, u_id[idx], u_cnt[idx]);
      end
   endgenerate

   coverage                         impl_cov(clk, rst_n, max_cnt, curr_cnt);


   //---------------
   // Implementation
   //---------------
   always_ff @(posedge clk iff rst_n == 1 or negedge rst_n)
   begin
      if (rst_n)
         curr_cnt <= next_cnt;
      else
         curr_cnt <= '0;
   end


   always_comb
      next_cnt =   curr_cnt ==  max_cnt  ?  '0  :  curr_cnt + 1;


   generate
      if (HIER_DEPTH > 0)
         assign my_id   = u_id[`N_OF_CHILDREN-1],
                sub_cnt = u_cnt.xor();
      else
         assign my_id   = i_id,
                sub_cnt = '0;
   endgenerate


   assign o_id = my_id + 1;


   assign max_cnt = my_id,
          o_cnt   = curr_cnt ^ sub_cnt;


   //---------------
   // Monitoring
   //---------------
`ifdef MSG_ON
   always @(posedge clk iff rst_n == 1)
      $strobe("@%t %m: cnt=%0d/%0d", $time, curr_cnt, max_cnt);
`endif


   overflow_ap: assert property
   (
      @(posedge clk)
      disable iff (rst_n != 1)
      curr_cnt == max_cnt |=> strong(curr_cnt == 0)
   )
   `ifdef MSG_ON
      $display("@%t %m: true", $time)
   `endif
      ;


   overflow_cp: cover property
   (
      @(posedge clk)
      disable iff (rst_n != 1)
      curr_cnt == max_cnt
   )
   `ifdef MSG_ON
      $display("@%t %m: true", $time);
   `endif
      ;
endmodule // node_scope



module harness;
   parameter OSC_START = 100;
   parameter OSC_PERIOD = 10;
   parameter OSC_HALF_PERIOD = OSC_PERIOD/2;
   parameter RST_START = 2*OSC_START;
   parameter RESET_CYCLES = (RST_START - OSC_START) / OSC_PERIOD + 1;


   bit                  clk;
   logic                rst_n;
   wire  [31:0]         cnt;    // count
   logic [31:0]         first_id;
   wire  [31:0]         next_id;


   //---------------
   // Instances
   //---------------
   node_scope#(`HIER_LEVELS)    top(clk, rst_n, first_id, next_id, cnt);


   //---------------
   // Initialization
   //---------------
   // oscillator
   initial
   begin
      #OSC_START $display("@%t run for %0d clock cycles", $time, next_id*`DURATION_IN_ROUNDS+RESET_CYCLES);
      repeat(2*(next_id*`DURATION_IN_ROUNDS+RESET_CYCLES))
      begin
         #OSC_HALF_PERIOD clk = !clk;
      end
   end


   // reset generator
   initial
   begin
      first_id = $urandom_range(1,32);
      $display("@%t first_id: %0d", $time, first_id);
      #RST_START   rst_n <= 0;
      #OSC_PERIOD  rst_n <= 1;
   end
endmodule // harness

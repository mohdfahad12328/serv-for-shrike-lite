`default_nettype none
`define BRAM_IMPL
// bram0 is of 4k block - 9 addr bits i.e 2^9 = 512
// 						- 8 data bits i.e 2^3 =   8
//											  =4096 bits
//                      4096/32 = 128 words (32 bit)
module servant_ram
  #(//Memory parameters
    parameter depth = 128,
    parameter aw    = $clog2(depth),
    parameter RESET_STRATEGY = "",
    parameter memfile = "")
   (
`ifdef BRAM_IMPL
   // bram ports
   	output [1:0] BRAM0_RATIO,
  	output reg [7:0] BRAM0_DATA_IN,
  	output reg BRAM0_WEN,
  	output reg BRAM0_WCLKEN,
  	output reg [8:0] BRAM0_WRITE_ADDR,
  	input [7:0] BRAM0_DATA_OUT,
  	output reg BRAM0_REN,
  	output reg BRAM0_RCLKEN,
  	output reg [8:0] BRAM0_READ_ADDR,
`endif
  	//
   input wire 		i_wb_clk,
    input wire 		i_wb_rst,
    input wire [aw-1:2] i_wb_adr,
    input wire [31:0] 	i_wb_dat,
    input wire [3:0] 	i_wb_sel,
    input wire 		i_wb_we,
    input wire 		i_wb_cyc,
    output reg [31:0] 	o_wb_rdt,
    output reg 		o_wb_ack);

`ifdef BRAM_IMPL
    assign BRAM0_RATIO = 2'b10; // 32 bit width
   // BRAM interface assignments
   always @(posedge i_wb_clk) begin
      BRAM0_WCLKEN <= i_wb_cyc & i_wb_we;
      BRAM0_RCLKEN <= i_wb_cyc & ~i_wb_we;
      BRAM0_WRITE_ADDR <= i_wb_adr[10:2]; // 9 bits for addr
      BRAM0_READ_ADDR <= i_wb_adr[10:2];
      BRAM0_WEN <= |(i_wb_sel & {4{i_wb_we & i_wb_cyc}});
      BRAM0_DATA_IN <=
         {i_wb_dat[31:24] & {8{ i_wb_sel[3] & i_wb_we & i_wb_cyc}},
          i_wb_dat[23:16] & {8{ i_wb_sel[2] & i_wb_we & i_wb_cyc}},
          i_wb_dat[15: 8] & {8{ i_wb_sel[1] & i_wb_we & i_wb_cyc}},
          i_wb_dat[ 7: 0] & {8{ i_wb_sel[0] & i_wb_we & i_wb_cyc}}};
   end

   always @(posedge i_wb_clk) begin
      if(i_wb_cyc & ~i_wb_we) begin
         o_wb_rdt <= {BRAM0_DATA_OUT, BRAM0_DATA_OUT, BRAM0_DATA_OUT, BRAM0_DATA_OUT};
      end
   end
`else
   // No BRAM implementation

   wire [3:0] 		we = {4{i_wb_we & i_wb_cyc}} & i_wb_sel;

   reg [31:0] 		mem [0:depth/4-1] /* verilator public */;

   wire [aw-3:0] 	addr = i_wb_adr[aw-1:2];

   always @(posedge i_wb_clk)
     if (i_wb_rst & (RESET_STRATEGY != "NONE"))
       o_wb_ack <= 1'b0;
     else
       o_wb_ack <= i_wb_cyc & !o_wb_ack;

	// reg [31:0] data_in;
	// always @(posedge i_wb_clk) begin
 //      if(we[0]) begin data_in[7:0] <= i_wb_dat[7:0]; end
 //      if(we[1]) begin data_in[15:8]  <= i_wb_dat[15:8]; end
 //      if(we[2]) begin data_in[23:16] <= i_wb_dat[23:16]; end
 //      if(we[3]) begin data_in[31:24] <= i_wb_dat[31:24]; end
 //      o_wb_rdt <= mem[addr];
	// end

   always @(posedge i_wb_clk) begin
      if(we[0]) begin mem[addr][7:0]   <= i_wb_dat[7:0]; end
      if(we[1]) begin mem[addr][15:8]  <= i_wb_dat[15:8]; end
      if(we[2]) begin mem[addr][23:16] <= i_wb_dat[23:16]; end
      if(we[3]) begin mem[addr][31:24] <= i_wb_dat[31:24]; end
      o_wb_rdt <= mem[addr];
   end
`endif
//    initial
//      if(|memfile) begin
// `ifndef ISE
// `ifndef CCGM
// 	$display("Preloading %m from %s", memfile);
// `endif
// `endif
// 	$readmemh(memfile, mem);
//      end

endmodule

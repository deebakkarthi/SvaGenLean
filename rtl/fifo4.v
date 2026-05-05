// 4-entry synchronous FIFO, 8-bit wide.
//
// Storage:    d0..d3 (explicit 8-bit registers for each slot)
// Pointers:   wptr[1:0], rptr[1:0]  (increment mod 4 on each accepted op)
// Count:      cnt[2:0]  (0 = empty, 4 = full)
//
// All control expressed as ternary assignments so the emitter can handle them.
//
//   Write: accepted when cnt != 3'd4 (not full)
//   Read:  accepted when cnt != 3'd0 (not empty)

module fifo4 (clk, wr_en, rd_en, din, dout, full, empty);
  input        clk, wr_en, rd_en;
  input  [7:0] din;
  output [7:0] dout;
  output       full, empty;

  reg [7:0] d0, d1, d2, d3;
  reg [1:0] wptr;
  reg [1:0] rptr;
  reg [2:0] cnt;

  assign dout  = (rptr == 2'd0) ? d0 :
                 (rptr == 2'd1) ? d1 :
                 (rptr == 2'd2) ? d2 : d3;
  assign full  = (cnt == 3'd4);
  assign empty = (cnt == 3'd0);

  always @(posedge clk) begin
    d0   <= (wr_en && (cnt != 3'd4) && (wptr == 2'd0)) ? din : d0;
    d1   <= (wr_en && (cnt != 3'd4) && (wptr == 2'd1)) ? din : d1;
    d2   <= (wr_en && (cnt != 3'd4) && (wptr == 2'd2)) ? din : d2;
    d3   <= (wr_en && (cnt != 3'd4) && (wptr == 2'd3)) ? din : d3;
    wptr <= (wr_en && (cnt != 3'd4)) ? (wptr + 2'd1) : wptr;
    rptr <= (rd_en && (cnt != 3'd0)) ? (rptr + 2'd1) : rptr;
    cnt  <= cnt + (wr_en && (cnt != 3'd4) ? 3'd1 : 3'd0)
               - (rd_en && (cnt != 3'd0) ? 3'd1 : 3'd0);
  end
endmodule

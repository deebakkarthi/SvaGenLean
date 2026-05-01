// 2-entry synchronous FIFO, 1-bit wide.
//
// Storage:    d0, d1 (explicit registers for each slot)
// Pointers:   wptr, rptr (1-bit, wrap automatically via ! toggle)
// Count:      cnt[1:0]  (0 = empty, 2 = full)
//
// All control expressed as ternary assignments so the emitter can handle them.
//
//   Write: accepted when cnt != 2 (not full)
//   Read:  accepted when cnt != 0 (not empty)

module fifo2 (clk, wr_en, rd_en, din, dout, full, empty);
  input  clk, wr_en, rd_en, din;
  output dout, full, empty;
  reg    d0, d1;
  reg    wptr;
  reg    rptr;
  reg [1:0] cnt;

  assign dout  = rptr ? d1 : d0;
  assign full  = (cnt == 2'd2);
  assign empty = (cnt == 2'd0);

  always @(posedge clk) begin
    d0   <= (wr_en && (cnt != 2'd2) && !wptr) ? din : d0;
    d1   <= (wr_en && (cnt != 2'd2) &&  wptr) ? din : d1;
    wptr <= (wr_en && (cnt != 2'd2)) ? !wptr : wptr;
    rptr <= (rd_en && (cnt != 2'd0)) ? !rptr : rptr;
    cnt  <= cnt + (wr_en && (cnt != 2'd2) ? 2'd1 : 2'd0)
               - (rd_en && (cnt != 2'd0) ? 2'd1 : 2'd0);
  end
endmodule

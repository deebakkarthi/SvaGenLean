`default_nettype none
module half_adder (
    input  wire a,
    input  wire b,
    output reg  sum,
    output reg  carry
);
  assign sum   = a ^ b;
  assign carry = a & b;
endmodule

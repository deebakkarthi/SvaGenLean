// =============================================================================
// 16-bit ALU — purely combinational, Verilog-1995
//
// Module hierarchy
//   cla_4            4-bit carry-lookahead adder with group P/G outputs
//   adder_16         16-bit adder: four cla_4 + second-level CLA
//   shifter_left_16  logical left barrel shifter, 4 MUX stages
//   shifter_right_16 logical right barrel shifter, 4 MUX stages
//   comparator_16    unsigned magnitude comparator
//   alu_16           top-level, selects output by 3-bit opcode
//
// op encoding
//   3'b000  ADD  (a + b)
//   3'b001  SUB  (a - b, via two's complement)
//   3'b010  AND  (a & b)
//   3'b011  OR   (a | b)
//   3'b100  XOR  (a ^ b)
//   3'b101  NOT  (~a)
//   3'b110  SHL  (a << shift_amt)
//   3'b111  SHR  (a >> shift_amt)
// =============================================================================

// -----------------------------------------------------------------------------
// 4-bit carry-lookahead adder
//   s[3:0]  sum bits
//   cout    carry out
//   c_msb   carry into the MSB of this group (for overflow detection)
//   grp_g   group generate (for second-level CLA)
//   grp_p   group propagate (for second-level CLA)
// -----------------------------------------------------------------------------
module cla_4 (
  input  [3:0] a,
  input  [3:0] b,
  input        cin,
  output [3:0] s,
  output       cout,
  output       c_msb,
  output       grp_g,
  output       grp_p
);
  wire [3:0] g, p;
  wire       c1, c2, c3;

  // Bit-level generate and propagate
  assign g = a & b;
  assign p = a ^ b;

  // Carry lookahead
  assign c1 = g[0] | (p[0] & cin);
  assign c2 = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
  assign c3 = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0])
                   | (p[2] & p[1] & p[0] & cin);

  assign cout = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1])
                     | (p[3] & p[2] & p[1] & g[0])
                     | (p[3] & p[2] & p[1] & p[0] & cin);

  // Sum
  assign s[0] = p[0] ^ cin;
  assign s[1] = p[1] ^ c1;
  assign s[2] = p[2] ^ c2;
  assign s[3] = p[3] ^ c3;

  // Carry into MSB of this group (for signed overflow detection upstream)
  assign c_msb = c3;

  // Group-level generate and propagate for second-level CLA
  assign grp_g = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1])
                       | (p[3] & p[2] & p[1] & g[0]);
  assign grp_p = p[3] & p[2] & p[1] & p[0];
endmodule

// -----------------------------------------------------------------------------
// 16-bit adder: four cla_4 blocks + second-level carry lookahead
//   overflow  signed overflow (carry into MSB XOR carry out of MSB)
// -----------------------------------------------------------------------------
module adder_16 (
  input  [15:0] a,
  input  [15:0] b,
  input         cin,
  output [15:0] s,
  output        cout,
  output        overflow
);
  wire [3:0] gg, gp;    // group generate / propagate from each cla_4
  wire       c1, c2, c3;
  wire       c_into_msb; // carry into bit 15, for overflow

  // Second-level CLA to compute inter-block carries in parallel
  assign c1 = gg[0] | (gp[0] & cin);
  assign c2 = gg[1] | (gp[1] & gg[0]) | (gp[1] & gp[0] & cin);
  assign c3 = gg[2] | (gp[2] & gg[1]) | (gp[2] & gp[1] & gg[0])
                    | (gp[2] & gp[1] & gp[0] & cin);

  cla_4 u0 (
    .a(a[3:0]),   .b(b[3:0]),   .cin(cin),
    .s(s[3:0]),   .cout(),      .c_msb(),
    .grp_g(gg[0]), .grp_p(gp[0])
  );
  cla_4 u1 (
    .a(a[7:4]),   .b(b[7:4]),   .cin(c1),
    .s(s[7:4]),   .cout(),      .c_msb(),
    .grp_g(gg[1]), .grp_p(gp[1])
  );
  cla_4 u2 (
    .a(a[11:8]),  .b(b[11:8]),  .cin(c2),
    .s(s[11:8]),  .cout(),      .c_msb(),
    .grp_g(gg[2]), .grp_p(gp[2])
  );
  cla_4 u3 (
    .a(a[15:12]), .b(b[15:12]), .cin(c3),
    .s(s[15:12]), .cout(cout),  .c_msb(c_into_msb),
    .grp_g(gg[3]), .grp_p(gp[3])
  );

  // Signed overflow: carry into sign bit differs from carry out of sign bit
  assign overflow = cout ^ c_into_msb;
endmodule

// -----------------------------------------------------------------------------
// 16-bit logical left barrel shifter
// Four cascaded MUX stages shift by 1, 2, 4, 8 depending on amt[3:0].
// -----------------------------------------------------------------------------
module shifter_left_16 (
  input  [15:0] in,
  input  [3:0]  amt,
  output [15:0] out
);
  wire [15:0] s1, s2, s4;

  assign s1  = amt[0] ? {in[14:0],  1'b0}       : in;
  assign s2  = amt[1] ? {s1[13:0],  2'b00}       : s1;
  assign s4  = amt[2] ? {s2[11:0],  4'b0000}     : s2;
  assign out = amt[3] ? {s4[7:0],   8'b00000000} : s4;
endmodule

// -----------------------------------------------------------------------------
// 16-bit logical right barrel shifter
// -----------------------------------------------------------------------------
module shifter_right_16 (
  input  [15:0] in,
  input  [3:0]  amt,
  output [15:0] out
);
  wire [15:0] s1, s2, s4;

  assign s1  = amt[0] ? {1'b0,        in[15:1]}  : in;
  assign s2  = amt[1] ? {2'b00,       s1[15:2]}  : s1;
  assign s4  = amt[2] ? {4'b0000,     s2[15:4]}  : s2;
  assign out = amt[3] ? {8'b00000000, s4[15:8]}  : s4;
endmodule

// -----------------------------------------------------------------------------
// 16-bit unsigned magnitude comparator
// -----------------------------------------------------------------------------
module comparator_16 (
  input  [15:0] a,
  input  [15:0] b,
  output        eq,
  output        lt,
  output        gt
);
  assign eq = (a == b);
  assign lt = (a <  b);
  assign gt = (a >  b);
endmodule

// -----------------------------------------------------------------------------
// 16-bit ALU — top level
//
// Inputs:
//   a, b       16-bit operands
//   op[2:0]    operation select (see op encoding at top of file)
//   shift_amt  shift amount for SHL / SHR (4-bit, 0-15)
//
// Outputs:
//   result     16-bit ALU result
//   zero       result == 0
//   carry_out  carry out of adder (unsigned overflow for ADD/SUB)
//   overflow   signed overflow from adder (ADD/SUB)
//   lt, eq, gt unsigned comparison outputs (reflect a vs b regardless of op)
// -----------------------------------------------------------------------------
module alu_16 (
  input  [15:0] a,
  input  [15:0] b,
  input  [2:0]  op,
  input  [3:0]  shift_amt,
  output [15:0] result,
  output        zero,
  output        carry_out,
  output        overflow,
  output        lt,
  output        eq,
  output        gt
);
  // For SUB, invert b and set carry-in to 1 (two's complement negation)
  wire [15:0] b_mux;
  wire        add_cin;
  wire [15:0] add_result;

  assign b_mux   = op[0] ? ~b : b;
  assign add_cin = op[0];

  adder_16 u_add (
    .a(a), .b(b_mux), .cin(add_cin),
    .s(add_result), .cout(carry_out), .overflow(overflow)
  );

  wire [15:0] shl_result, shr_result;

  shifter_left_16  u_shl (.in(a), .amt(shift_amt), .out(shl_result));
  shifter_right_16 u_shr (.in(a), .amt(shift_amt), .out(shr_result));

  comparator_16 u_cmp (.a(a), .b(b), .eq(eq), .lt(lt), .gt(gt));

  // Result mux — combinational always with full sensitivity list
  reg [15:0] res;
  always @(a or b or op or add_result or shl_result or shr_result) begin
    case (op)
      3'b000:  res = add_result;
      3'b001:  res = add_result;
      3'b010:  res = a & b;
      3'b011:  res = a | b;
      3'b100:  res = a ^ b;
      3'b101:  res = ~a;
      3'b110:  res = shl_result;
      default: res = shr_result;
    endcase
  end

  assign result = res;
  assign zero   = (result == 16'b0);
endmodule

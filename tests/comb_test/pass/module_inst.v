// Module instantiation — internals are unknown, must be rejected
module sub (input a, output y);
  assign y = ~a;
endmodule

module module_inst (input a, output y);
  sub u0 (.a(a), .y(y));
endmodule

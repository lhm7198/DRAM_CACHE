/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Ultra(TM) in wire load mode
// Version   : Q-2019.12-SP5-5
// Date      : Tue Jun 28 15:58:57 2022
/////////////////////////////////////////////////////////////


module ADDER ( clk, rst_n, a, b, c );
  input [3:0] a;
  input [3:0] b;
  output [4:0] c;
  input clk, rst_n;
  wire   \*Logic0* , N1;
  assign c[1] = \*Logic0* ;
  assign c[2] = \*Logic0* ;
  assign c[3] = \*Logic0* ;
  assign c[4] = \*Logic0* ;

  SVM_FDPRBQ_V2_1 reg_c_reg ( .D(N1), .CK(clk), .RD(rst_n), .Q(c[0]) );
  SVR_TIE0_1 U5 ( .X(\*Logic0* ) );
  SVM_EO2_V2_0P5 U6 ( .A1(b[0]), .A2(a[0]), .X(N1) );
endmodule


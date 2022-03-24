//This module assumes the Basys3 board connections for 4 digit 7 segment display

module FourSegDisplay (
//Global Signals
  input        clk
, input        rst 

//CPU Bus Interface
, input      [1:0] Address
, input      [7:0] Data_Bus_in
, output reg [7:0] Data_Bus_out
, input            Cen
, input            Rd
, input            Wr

//IO Control Ports
, output wire segA
, output wire segB
, output wire segC
, output wire segD
, output wire segE
, output wire segF
, output wire segG
, output wire segDP

, output wire [3:0] segAnode
);

  //Bus Interface Logic
  wire rstb = ~rst;
  
  //Control Register
  reg [7:0] Control; 

  //Clock Divider Control for switching segments
  reg [7:0] Divisor;

  //Values to show on the Seven Segment display
  reg [7:0] SegmentPairA;
  reg [7:0] SegmentPairB;

  //CPU BUS READ HANDLER
  always @ (posedge clk or negedge rst) //Same reset polarity as cpu
    if( rst == 1'b0 )
      Data_Bus_out <= 8'h00;
    else if ( Rd == 1'b1 )
      case( Address )
        2'b00 : Data_Bus_out <= Control;
        2'b01 : Data_Bus_out <= Divisor; 
        2'b10 : Data_Bus_out <= SegmentPairA;
        2'b11 : Data_Bus_out <= SegmentPairB;
      endcase
    else
      Data_Bus_out <= Data_Bus_out;

  //CPU BUS WRITE HANDLER
  always @ (negedge clk or posedge rstb)
    if( rstb == 1'b1 ) 
      begin
        Control      = 8'h00;
        Divisor      = 8'h00;
        SegmentPairA = 8'h00;
        SegmentPairB = 8'h00;
      end
    else if (Wr == 1'b1)
      case(Address)
        2'b00   : begin
                    Control      = Data_Bus_in;
                    Divisor      = Divisor;
                    SegmentPairA = SegmentPairA;
                    SegmentPairB = SegmentPairB;
                  end
        2'b01   : begin
                    Control      = Control;
                    Divisor      = Data_Bus_in;
                    SegmentPairA = SegmentPairA;
                    SegmentPairB = SegmentPairB;
                  end
        2'b10   : begin
                    Control      = Control;
                    Divisor      = Divisor;
                    SegmentPairA = Data_Bus_in;
                    SegmentPairB = SegmentPairB;
                  end
        2'b11   : begin
                    Control      = Control;
                    Divisor      = Divisor;
                    SegmentPairA = SegmentPairA;
                    SegmentPairB = Data_Bus_in;
                  end
        default : begin
                    Control      = Control;
                    Divisor      = Divisor;
                    SegmentPairA = SegmentPairA;
                    SegmentPairB = SegmentPairB;
                  end
      endcase
    else
      begin
        Control      = Control;
        Divisor      = Divisor;
        SegmentPairA = SegmentPairA;
        SegmentPairB = SegmentPairB;
      end

  //IO Peripheral Logic
  reg  [5:0] Bit;
  wire [3:0] BitA = SegmentPairA[7:4]; 
  wire [3:0] BitB = SegmentPairA[3:0]; 
  wire [3:0] BitC = SegmentPairB[7:4]; 
  wire [3:0] BitD = SegmentPairB[3:0]; 
  wire [6:0] Segments;
  wire       SegmentsDp;

  //Segment wires from Controller
  assign segDP = SegmentsDp;
  assign segA  = Segments[6];
  assign segB  = Segments[5];
  assign segC  = Segments[4];
  assign segD  = Segments[3];
  assign segE  = Segments[2];
  assign segF  = Segments[1];
  assign segG  = Segments[0];
  
  //Choose which nibble to display
  always @*
    case(segAnode)
      4'b0111 : Bit <= {Control[7:6], BitA};
      4'b1011 : Bit <= {Control[5:4], BitB};
      4'b1101 : Bit <= {Control[3:2], BitC};
      4'b1110 : Bit <= {Control[1:0], BitD};
      default : Bit <= 6'b000000;
    endcase
  
  reg  [23:0] Counter  = 0;
  wire [23:0] Divider  = {Divisor, 16'h0000};
  wire        advAnode = (Divider == Counter);
  
  always @ (posedge clk or negedge rst)
    if( rst == 1'b0 )
      Counter <= 0;
    else if( advAnode == 1'b1 )
      Counter <= 0;
    else
      Counter <= Counter + 1;
  
  SegmentDecoder segmentDec   (clk, rst, advAnode, Bit[5], Bit[4], Bit[3:0], segAnode, Segments, SegmentsDp);

endmodule

module SegmentDecoder (
  input             clk
, input             rst

, input             advAnode
, input             Blank
, input             Dpi
, input       [3:0] Digit

, output reg  [3:0] Anodes
, output reg  [6:0] Segments
, output wire       Dpo
);
  
  reg [3:0] pAnode = 4'b1111;
  reg [3:0] nAnode = 4'b1111;
  always @ (posedge clk or negedge rst)
    if( rst == 1'b0 )
      pAnode <= 4'b1111;
    else if( advAnode == 1'b1 )
      pAnode <= nAnode;
    else
      pAnode <= pAnode;
  
  always @*
    case(pAnode)
      4'b1110 : if( Blank ) Anodes <= 4'b1111; else Anodes <= 4'b1110; 
      4'b1101 : if( Blank ) Anodes <= 4'b1111; else Anodes <= 4'b1101;
      4'b1011 : if( Blank ) Anodes <= 4'b1111; else Anodes <= 4'b1011;
      4'b0111 : if( Blank ) Anodes <= 4'b1111; else Anodes <= 4'b0111;
      default : Anodes <= 4'b1111;
    endcase
  
  always @*
    case(pAnode)
      4'b1111 : nAnode <= 4'b0111;
      4'b1110 : nAnode <= 4'b0111; 
      4'b1101 : nAnode <= 4'b1110;
      4'b1011 : nAnode <= 4'b1101;
      4'b0111 : nAnode <= 4'b1011;
      default : nAnode <= 4'b1111;
    endcase
  
  assign Dpo = Dpi;
  always @*
    case(Digit)
      //                      A B C D E F G  DISPLAY SHOWS
      4'h0    : Segments = 7'b0_0_0_0_0_0_1; //0
      4'h1    : Segments = 7'b1_0_0_1_1_1_1; //1
      4'h2    : Segments = 7'b0_0_1_0_0_1_0; //2
      4'h3    : Segments = 7'b0_0_0_0_1_1_0; //3
      4'h4    : Segments = 7'b1_0_0_1_1_0_0; //4
      4'h5    : Segments = 7'b0_1_0_0_1_0_0; //5
      4'h6    : Segments = 7'b0_1_0_0_0_0_0; //6
      4'h7    : Segments = 7'b0_0_0_1_1_1_1; //7
      4'h8    : Segments = 7'b0_0_0_0_0_0_0; //8
      4'h9    : Segments = 7'b0_0_0_0_1_0_0; //9
      4'ha    : Segments = 7'b0_0_0_1_0_0_0; //A
      4'hb    : Segments = 7'b1_1_0_0_0_0_0; //b
      4'hc    : Segments = 7'b0_1_1_0_0_0_1; //C
      4'hd    : Segments = 7'b1_0_0_0_0_1_0; //d
      4'he    : Segments = 7'b0_1_1_0_0_0_0; //E
      4'hf    : Segments = 7'b0_1_1_1_0_0_0; //F
      default : Segments = 7'h7f;
    endcase

endmodule

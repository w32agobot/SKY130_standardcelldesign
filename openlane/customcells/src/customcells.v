`default_nettype none
//  Copyright 2022 Manuel Moser
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.

module customcells(
    in,
    out,
);
    input in;
    output out;
   
   // Internal wires
    wire net1;
   
   //combinatoric
    N_customcells #(.Ntimes(123)) some_customcells (.in(in), .out(net1));
    assign out = ~net1;
    
endmodule


// ##############################################
//
// Module with N times Custom-Standardcells in series configuration
//
module N_customcells #(parameter Ntimes = 4)
(
    in,
    out
);
    input  in;
    output out;
    wire [Ntimes:1] _intsig_a_;
    wire [Ntimes:1] _intsig_b_;
    
    genvar j;
    generate
       for(j=1;j<= Ntimes;j=j+1) begin
          sky130_customcell name_of_cell (.in(_intsig_a_[j]), .out(_intsig_b_[j]));    
       end
       for(j=1;j< Ntimes;j=j+1) begin
          assign _intsig_a_[j+1] = _intsig_b_[j];   
       end
    assign _intsig_a_[1] = in;
    assign _intsig_b_[Ntimes] = out;
    endgenerate
endmodule












module dimm(addr, ba, rasx, casx, csx, wex, cke, clk, dqm, data, dev_id);
parameter [31:0] MEM_WIDTH = 16, MEM_SIZE = 8; // in mbytes
input [10:0] addr;                       
input ba, rasx, casx, csx, wex, cke, clk;
input [ 7:0] dqm;                        
inout [63:0] data;                       
input [ 4:0] dev_id;                     

genvar i;
case ({MEM_SIZE, MEM_WIDTH})
  {32'd8, 32'd16}: // 8Meg x 16 bits wide
    begin: memory
      for (i=0; i<4; i=i+1) begin:word16
        sms_08b216t0 p(.clk(clk), .csb(csx), .cke(cke),.ba(ba),
                       .addr(addr), .rasb(rasx), .casb(casx),
                       .web(wex), .udqm(dqm[2*i+1]), .ldqm(dqm[2*i]),
                       .dqi(data[15+16*i:16*i]), .dev_id(dev_id));
      end
      task read_mem;
        input [31:0] address;
        output [63:0] data;
        begin
          // call read_mem in sms module
          word[3].p.read_mem(address, data[63:48]);
          word[2].p.read_mem(address, data[47:32]);
          word[1].p.read_mem(address, data[31:16]);
          word[0].p.read_mem(address, data[15: 0]);
        end
      endtask
   end
  {32'd16, 32'd8}: // 16Meg x 8 bits wide
    begin: memory
      for (i=0; i<8; i=i+1) begin:word8
        sms_16b208t0 p(.clk(clk), .csb(csx), .cke(cke),.ba(ba),
                       .addr(addr), .rasb(rasx), .casb(casx),
                       .web(wex), .dqm(dqm[i]),
                       .dqi(data[7+8*i:8*i]), .dev_id(dev_id));
      end
      task read_mem;
        input [31:0] address;
        output [63:0] data;
        begin
          // call read_mem in sms module
          mbyte[7].p.read_mem(address, data[63:56]);
          mbyte[6].p.read_mem(address, data[55:48]);
          mbyte[5].p.read_mem(address, data[47:40]);
          mbyte[4].p.read_mem(address, data[39:32]);
          mbyte[3].p.read_mem(address, data[31:24]);
          mbyte[2].p.read_mem(address, data[23:16]);
          mbyte[1].p.read_mem(address, data[15: 8]);
          mbyte[0].p.read_mem(address, data[ 7: 0]);
        end
      endtask
   end
// Other memory cases ...
endcase
endmodule

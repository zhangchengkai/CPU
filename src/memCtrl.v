`include "constant.v"

module memCtrl(
    input clk,
    input rst,
    input rdy,

    //check uart is full
    input in_uart_full,

    //requires from fetcher
    input in_fetcher_ce,
    input [`DATA_WIDTH] in_fetcher_addr,

    //feedback to fetcher
    output reg out_fetcher_ce,

    //requires from slb for read
    input in_slb_ce,
    input [`DATA_WIDTH] in_slb_addr,
    input [5:0] in_slb_size,
    input in_slb_signed,

    //feedback to slb
    output reg out_slb_ce,

    //requires from rob for write
    input in_rob_ce,
    input [`DATA_WIDTH] in_rob_addr,
    input [5:0] in_rob_size,
    input [`DATA_WIDTH] in_rob_data,

    //??
    input in_rob_load_ce,

    //feedback to rob
    output reg out_rob_ce,

    //feedback data
    output reg [`DATA_WIDTH] out_data,

    //commmunicate with ram
    output reg out_ram_rw,  //0:read,  1:write
    output reg [`DATA_WIDTH] out_ram_address,
    output reg [7:0] out_ram_data,
    input [7:0] in_ram_data,

    //is misbranch from rob
    input in_rob_misbranch
);
    localparam IDLE         = 0,
               FETCHER_READ = 1,
               SLB_READ     = 2,
               ROB_WRITE    = 3,
               IO_READ      = 4;

    reg fetcher_flag;
    reg slb_flag;
    reg rob_flag;
    reg io_flag;
    reg [5:0] stages;
    reg [2:0] status;
    wire [2:0] buffered_status;
    wire [7:0] buffered_wire_data;
    wire disable_to_write;
    //stall 2 cycles for uart_full
    reg [1:0] wait_uart;

    //write_buffer control
    wire wb_is_empty;
    wire wb_is_full;
    reg [`WB_TAG_WIDTH] head;
    reg [`WB_TAG_WIDTH] tail;
    reg [`DATA_WIDTH] wb_data [(`WB_SIZE-1):0];
    reg [`DATA_WIDTH] wb_addr [(`WB_SIZE-1):0];
    reg [5:0] wb_size [(`WB_SIZE-1):0];
    wire [`WB_TAG_WIDTH] nextPtr = (tail+1) % (`WB_SIZE);
    wire [`WB_TAG_WIDTH] nowPtr  = (head+1) % (`WB_SIZE);
    assign wb_is_empty = (head == tail)    ? `TRUE : `FALSE;
    assign wb_is_full  = (nextPtr == head) ? `TRUE : `FALSE;
    assign disable_to_write = (in_uart_full == `TRUE || wait_uart != 0) && (ab_addr[nowPtr][17:16] == 2`b11);
    
    //to be continued
    always @(posedge clk) begin
        if(rst == `TRUE) begin
        end else if(rdy == `TRUE) begin
        end
    end
endmodule
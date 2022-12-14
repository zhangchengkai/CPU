// RISCV32I CPU top module
// port modification allowed for debugging purposes

module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here
wire bp_to_fetcher_jump_ce;

wire fetcher_to_mem_ce;
wire [`DATA_WIDTH] fetcher_to_mem_pc;
wire [`DATA_WIDTH] fetcher_to_decoder_instr;
wire [`DATA_WIDTH] fetcher_to_decoder_pc;
wire fetcher_to_decoder_jump_ce;
wire [`BP_TAG_WIDTH] fetcher_to_bp_tag;
wire fetcher_out_store_ce;

wire [`REG_TAG_WIDTH] decoder_to_reg_tag1;
wire [`REG_TAG_WIDTH] decoder_to_reg_tag2;
wire [`REG_TAG_WIDTH] decoder_to_reg_destination;
wire [`ROB_TAG_WIDTH] decoder_to_reg_robtag;
wire [`ROB_TAG_WIDTH] decoder_to_rob_fetch_tag1;
wire [`ROB_TAG_WIDTH] decoder_to_rob_fetch_tag2;
wire [`DATA_WIDTH] decoder_to_rob_store_destination;
wire [`INSIDE_OPCODE_WIDTH] decoder_to_rob_store_op;
wire decoder_to_rob_jump_ce;
wire [`ROB_TAG_WIDTH] decoder_to_rs_rob_tag;
wire [`INSIDE_OPCODE_WIDTH] decoder_to_rs_op;
wire [`DATA_WIDTH] decoder_to_rs_value1;
wire [`DATA_WIDTH] decoder_to_rs_value2;
wire [`ROB_TAG_WIDTH] decoder_to_rs_tag1;
wire [`ROB_TAG_WIDTH] decoder_to_rs_tag2;
wire [`DATA_WIDTH] decoder_to_rs_imm;
wire [`DATA_WIDTH] decoder_to_rs_pc;
wire [`ROB_TAG_WIDTH] decoder_to_slb_rob_tag;
wire [`INSIDE_OPCODE_WIDTH] decoder_to_slb_op;
wire [`DATA_WIDTH] decoder_to_slb_value1;
wire [`DATA_WIDTH] decoder_to_slb_value2;
wire [`ROB_TAG_WIDTH] decoder_to_slb_tag1;
wire [`ROB_TAG_WIDTH] decoder_to_slb_tag2;
wire [`DATA_WIDTH] decoder_to_slb_imm;

wire mem_to_fetcher_ce;
wire mem_to_slb_ce;
wire mem_to_rob_ce;
wire [`DATA_WIDTH] mem_out_data;

wire [`DATA_WIDTH] reg_to_decoder_value1;
wire [`ROB_TAG_WIDTH] reg_to_decoder_robtag1;
wire reg_to_decoder_busy1;
wire [`DATA_WIDTH] reg_to_decoder_value2;
wire [`ROB_TAG_WIDTH] reg_to_decoder_robtag2;
wire reg_to_decoder_busy2;

wire rs_to_fetcher_idle;
wire [`INSIDE_OPCODE_WIDTH] rs_to_alu_op;
wire [`DATA_WIDTH] rs_to_alu_value1;
wire [`DATA_WIDTH] rs_to_alu_value2;
wire [`DATA_WIDTH] rs_to_alu_imm;
wire [`ROB_TAG_WIDTH] rs_to_alu_rob_tag;
wire [`DATA_WIDTH] rs_to_alu_pc;

wire slb_to_fetcher_idle;
wire [`DATA_WIDTH] slb_out_cdb_value;
wire [`ROB_TAG_WIDTH] slb_out_cdb_tag;
wire [`DATA_WIDTH] slb_out_cdb_destination;
wire [`DATA_WIDTH] slb_to_rob_address;
wire slb_to_mem_ce;
wire [5:0] slb_to_mem_size;
wire slb_to_mem_signed;
wire [`DATA_WIDTH] slb_to_mem_address;
wire slb_out_ioin;

wire rob_to_fetcher_idle;
wire rob_out_misbranch;
wire [`DATA_WIDTH] rob_to_fetcher_newpc;
wire [`ROB_TAG_WIDTH] rob_to_decoder_freetag;
wire [`DATA_WIDTH] rob_to_decoder_fetch_value1;
wire rob_to_decoder_fetch_ready1;
wire [`DATA_WIDTH] rob_to_decoder_fetch_value2;
wire rob_to_decoder_fetch_ready2;
wire rob_to_slb_check;
wire [`REG_TAG_WIDTH] rob_to_reg_index;
wire [`ROB_TAG_WIDTH] rob_to_reg_rob_tag;
wire [`DATA_WIDTH] rob_to_reg_value;
wire rob_to_mem_ce;
wire [5:0] rob_to_mem_size;
wire [`DATA_WIDTH] rob_to_mem_address;
wire [`DATA_WIDTH] rob_to_mem_data;
wire rob_to_bp_ce;
wire [`BP_TAG_WIDTH] rob_to_bp_tag;
wire rob_to_bp_jump_ce;
wire rob_to_mem_load_ce;
wire [`ROB_TAG_WIDTH] rob_out_tag;
wire [`DATA_WIDTH] rob_out_value;

wire [`DATA_WIDTH] alu_out_cdb_value;
wire [`ROB_TAG_WIDTH] alu_out_cdb_tag;
wire [`DATA_WIDTH] alu_out_cdb_newpc;


// module implementation
fetcher fetcher_unit(
  .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
  .out_mem_ce(fetcher_to_mem_ce), .out_mem_pc(fetcher_to_mem_pc),
  .in_mem_ce(mem_to_fetcher_ce), .in_mem_instr(mem_out_data),
  .out_instr(fetcher_to_decoder_instr), .out_pc(fetcher_to_decoder_pc), .out_jump_ce(fetcher_to_decoder_jump_ce),
  .in_rs_idle(rs_to_fetcher_idle), .in_slb_idle(slb_to_fetcher_idle), .in_rob_idle(rob_to_fetcher_idle),
  .out_store_ce(fetcher_out_store_ce),
  .in_rob_misbranch(rob_out_misbranch), .in_rob_newpc(rob_to_fetcher_newpc),
  .out_bp_tag(fetcher_to_bp_tag), .in_bp_jump_ce(bp_to_fetcher_jump_ce)
);

decode decode_unit(
  .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
  .in_fetcher_instr(fetcher_to_decoder_instr), .in_fetcher_pc(fetcher_to_decoder_pc), .in_fetcher_jump_ce(fetcher_to_decoder_jump_ce),
  .out_reg_tag1(decoder_to_reg_tag1), .in_reg_value1(reg_to_decoder_value1), .in_reg_robtag1(reg_to_decoder_robtag1), .in_reg_busy1(reg_to_decoder_busy1), 
  .out_reg_tag2(decoder_to_reg_tag2), .in_reg_value2(reg_to_decoder_value2), .in_reg_robtag2(reg_to_decoder_robtag2), .in_reg_busy2(reg_to_decoder_busy2),
  .out_reg_destination(decoder_to_reg_destination), .out_reg_rob_tag(decoder_to_reg_robtag),
  .in_rob_freetag(rob_to_decoder_freetag),
  .out_rob_fetch_tag1(decoder_to_rob_fetch_tag1), .in_rob_fetch_value1(rob_to_decoder_fetch_value1), .in_rob_fetch_ready1(rob_to_decoder_fetch_ready1), 
  .out_rob_fetch_tag2(decoder_to_rob_fetch_tag2), .in_rob_fetch_value2(rob_to_decoder_fetch_value2), .in_rob_fetch_ready2(rob_to_decoder_fetch_ready2), 
  .out_rob_destination(decoder_to_rob_store_destination), .out_rob_op(decoder_to_rob_store_op), .out_rob_jump_ce(decoder_to_rob_jump_ce),
  .out_rs_rob_tag(decoder_to_rs_rob_tag), .out_rs_op(decoder_to_rs_op), .out_rs_value1(decoder_to_rs_value1), .out_rs_value2(decoder_to_rs_value2),
  .out_rs_tag1(decoder_to_rs_tag1), .out_rs_tag2(decoder_to_rs_tag2), .out_rs_imm(decoder_to_rs_imm), .out_pc(decoder_to_rs_pc),
  .out_slb_rob_tag(decoder_to_slb_rob_tag), .out_slb_op(decoder_to_slb_op), .out_slb_value1(decoder_to_slb_value1), .out_slb_value2(decoder_to_slb_value2), 
  .out_slb_tag1(decoder_to_slb_tag1), .out_slb_tag2(decoder_to_slb_tag2), .out_slb_imm(decoder_to_slb_imm)
);

rs rs_unit(
  .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
  .in_fetcher_ce(fetcher_out_store_ce),
  .out_fetcher_isidle(rs_to_fetcher_idle),
  .in_decode_rob_tag(decoder_to_rs_rob_tag), .in_decode_op(decoder_to_rs_op), .in_decode_value1(decoder_to_rs_value1), .in_decode_value2(decoder_to_rs_value2),
  .in_decode_imm(decoder_to_rs_imm), .in_decode_tag1(decoder_to_rs_tag1), .in_decode_tag2(decoder_to_rs_tag2), .in_decode_pc(decoder_to_rs_pc),
  .in_alu_cdb_value(alu_out_cdb_value), .in_alu_cdb_tag(alu_out_cdb_tag),
  .in_slb_cdb_value(slb_out_cdb_value), .in_slb_cdb_tag(slb_out_cdb_tag),
  .in_slb_ioin(slb_out_ioin),
  .in_rob_cdb_tag(rob_out_tag), .in_rob_cdb_value(rob_out_value),
  .out_alu_op(rs_to_alu_op), .out_alu_value1(rs_to_alu_value1), .out_alu_value2(rs_to_alu_value2), 
  .out_alu_imm(rs_to_alu_imm), .out_alu_rob_tag(rs_to_alu_rob_tag), .out_alu_pc(rs_to_alu_pc),
  .in_rob_misbranch(rob_out_misbranch)
);

slb slb_unit(
  .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
  .in_fetcher_ce(fetcher_out_store_ce),
  .out_fetcher_isidle(slb_to_fetcher_idle),
  .in_decode_rob_tag(decoder_to_slb_rob_tag), .in_decode_op(decoder_to_slb_op), .in_decode_value1(decoder_to_slb_value1), .in_decode_value2(decoder_to_slb_value2),
  .in_decode_imm(decoder_to_slb_imm), .in_decode_tag1(decoder_to_slb_tag1), .in_decode_tag2(decoder_to_slb_tag2),
  .out_rob_now_addr(slb_to_rob_address), .in_rob_check(rob_to_slb_check),
  .in_alu_cdb_tag(alu_out_cdb_tag), .in_alu_cdb_value(alu_out_cdb_value),
  .in_rob_cdb_tag(rob_out_tag), .in_rob_cdb_value(rob_out_value),
  .out_mem_ce(slb_to_mem_ce), .out_mem_size(slb_to_mem_size), .out_mem_signed(slb_to_mem_signed), .out_mem_address(slb_to_mem_address),
  .in_mem_ce(mem_to_slb_ce), .in_mem_data(mem_out_data),
  .out_rob_tag(slb_out_cdb_tag), .out_destination(slb_out_cdb_destination), .out_value(slb_out_cdb_value),
  .out_ioin(slb_out_ioin),
  .in_rob_misbranch(rob_out_misbranch)
);

rob rob_unit(
  .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
  .out_decode_idle_tag(rob_to_decoder_freetag),
  .in_decode_destination(decoder_to_rob_store_destination), .in_decode_op(decoder_to_rob_store_op), .in_decode_pc(decoder_to_rs_pc), .in_decode_jump_ce(decoder_to_rob_jump_ce),
  .in_decode_fetch_tag1(decoder_to_rob_fetch_tag1), .out_decode_fetch_value1(rob_to_decoder_fetch_value1), .out_decode_fetch_ready1(rob_to_decoder_fetch_ready1),
  .in_decode_fetch_tag2(decoder_to_rob_fetch_tag2), .out_decode_fetch_value2(rob_to_decoder_fetch_value2), .out_decode_fetch_ready2(rob_to_decoder_fetch_ready2),
  .out_fetcher_isidle(rob_to_fetcher_idle),
  .in_fetcher_ce(fetcher_out_store_ce),
  .in_alu_cdb_value(alu_out_cdb_value), .in_alu_cdb_newpc(alu_out_cdb_newpc), .in_alu_cdb_tag(alu_out_cdb_tag),
  .in_slb_cdb_tag(slb_out_cdb_tag), .in_slb_cdb_value(slb_out_cdb_value), .in_slb_cdb_destination(slb_out_cdb_destination),
  .in_slb_ioin(slb_out_ioin),
  .in_slb_now_addr(slb_to_rob_address), .out_slb_check(rob_to_slb_check),
  .out_reg_index(rob_to_reg_index), .out_reg_rob_tag(rob_to_reg_rob_tag), .out_reg_value(rob_to_reg_value),
  .out_mem_ce(rob_to_mem_ce), .out_mem_size(rob_to_mem_size), .out_mem_address(rob_to_mem_address), .out_mem_data(rob_to_mem_data), .in_mem_ce(mem_to_rob_ce),
  .out_mem_load_ce(rob_to_mem_load_ce), .in_mem_data(mem_out_data),
  .out_misbranch(rob_out_misbranch), .out_newpc(rob_to_fetcher_newpc),
  .out_bp_ce(rob_to_bp_ce), .out_bp_tag(rob_to_bp_tag), .out_bp_jump_ce(rob_to_bp_jump_ce),
  .out_rob_tag(rob_out_tag), .out_value(rob_out_value)
);

alu alu_unit(
  .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
  .in_op(rs_to_alu_op), .in_value1(rs_to_alu_value1), .in_value2(rs_to_alu_value2), .in_imm(rs_to_alu_imm), .in_pc(rs_to_alu_pc), .in_rob_tag(rs_to_alu_rob_tag),
  .out_rob_tag(alu_out_cdb_tag), .out_value(alu_out_cdb_value), .out_newpc(alu_out_cdb_newpc)
);

memCtrl memory_unit(
  .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
  .in_fetcher_ce(fetcher_to_mem_ce), .in_fetcher_addr(fetcher_to_mem_pc),
  .out_fetcher_ce(mem_to_fetcher_ce),
  .in_slb_ce(slb_to_mem_ce), .in_slb_addr(slb_to_mem_address), .in_slb_size(slb_to_mem_size), .in_slb_signed(slb_to_mem_signed),
  .out_slb_ce(mem_to_slb_ce),
  .in_rob_ce(rob_to_mem_ce), .in_rob_addr(rob_to_mem_address), .in_rob_size(rob_to_mem_size), .in_rob_data(rob_to_mem_data),
  .in_rob_load_ce(rob_to_mem_load_ce),
  .out_rob_ce(mem_to_rob_ce),
  .out_data(mem_out_data),
  .out_ram_rw(mem_wr), .out_ram_address(mem_a), .out_ram_data(mem_dout), .in_ram_data(mem_din),
  .in_rob_misbranch(rob_out_misbranch),
  .in_uart_full(io_buffer_full)
);

register regfile_unit(
  .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
  .in_fetcher_ce(fetcher_out_store_ce),
  .in_decode_reg_tag1(decoder_to_reg_tag1), .out_decode_value1(reg_to_decoder_value1), .out_decode_rob_tag1(reg_to_decoder_robtag1), .out_decode_busy1(reg_to_decoder_busy1),
  .in_decode_reg_tag2(decoder_to_reg_tag2), .out_decode_value2(reg_to_decoder_value2), .out_decode_rob_tag2(reg_to_decoder_robtag2), .out_decode_busy2(reg_to_decoder_busy2),
  .in_decode_destination_reg(decoder_to_reg_destination), .in_decode_destination_rob(decoder_to_reg_robtag),
  .in_rob_commit_reg(rob_to_reg_index), .in_rob_commit_rob(rob_to_reg_rob_tag), .in_rob_commit_value(rob_to_reg_value),
  .in_rob_misbranch(rob_out_misbranch)
);

bp branchPredictor_unit(
  .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
  .in_fetcher_tag(fetcher_to_bp_tag),
  .out_fetcher_jump_ce(bp_to_fetcher_jump_ce),
  .in_rob_bp_ce(rob_to_bp_ce),
  .in_rob_tag(rob_to_bp_tag),
  .in_rob_jump_ce(rob_to_bp_jump_ce)
);

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)
endmodule
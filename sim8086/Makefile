.PHONY: asm decode/single decode/many

all: decode/single decode/many decode/more decode/challenge decode/add_sub_cmp_jnz

asm:
	@nasm single_register_mov.asm
	@nasm many_register_mov.asm
	@nasm more_movs.asm
	@nasm challenge_movs.asm
	@nasm add_sub_cmp_jnz.asm

decode/single: asm
	@echo ">> single <<"
	@zig build run -- single_register_mov > out.asm
	@echo "comparing results..."
	@nasm out.asm
	@diff out single_register_mov
	@echo "success!"
	@rm -rf out out.asm

decode/many: asm
	@echo ">> many <<"
	@zig build run -- many_register_mov > out.asm
	@echo "comparing results..."
	@nasm out.asm
	@diff out many_register_mov
	@echo "success!"
	@rm -rf out out.asm

decode/more: asm
	@echo ">> more <<"
	@zig build run -- more_movs > out.asm
	@echo "comparing results..."
	@nasm out.asm
	@diff out more_movs
	@echo "success!"
	@rm -rf out out.asm

decode/challenge: asm
	@echo ">> challenge <<"
	@zig build run -- challenge_movs > out.asm
	@echo "comparing results..."
	@nasm out.asm
	@diff out challenge_movs
	@echo "success!"
	@rm -rf out out.asm

decode/add_sub_cmp_jnz: asm
	@echo ">> add_sub_cmp_jnz <<"
	@zig build run -- add_sub_cmp_jnz > out.asm
	@echo "comparing results..."
	@nasm out.asm
	@diff out add_sub_cmp_jnz
	@echo "success!"
	@rm -rf out out.asm

clean:
	rm -rf out out.asm
	rm -rf single_register_mov many_register_mov more_movs challenge_movs add_sub_cmp_jnz

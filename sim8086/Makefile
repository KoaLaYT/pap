.PHONY: asm decode/single decode/many decode/more decode/challenge decode/add_sub_cmp_jnz

all: decode/single decode/many decode/more decode/challenge decode/add_sub_cmp_jnz

asm:
	@nasm asm/single_register_mov.asm
	@nasm asm/many_register_mov.asm
	@nasm asm/more_movs.asm
	@nasm asm/challenge_movs.asm
	@nasm asm/add_sub_cmp_jnz.asm

decode/single: asm
	@echo ">> single <<"
	@zig build dumpdecode -- asm/single_register_mov > out.asm
	@echo "comparing results..."
	@nasm out.asm
	@diff out asm/single_register_mov
	@echo "success!"
	@rm -rf out out.asm

decode/many: asm
	@echo ">> many <<"
	@zig build dumpdecode -- asm/many_register_mov > out.asm
	@echo "comparing results..."
	@nasm out.asm
	@diff out asm/many_register_mov
	@echo "success!"
	@rm -rf out out.asm

decode/more: asm
	@echo ">> more <<"
	@zig build dumpdecode -- asm/more_movs > out.asm
	@echo "comparing results..."
	@nasm out.asm
	@diff out asm/more_movs
	@echo "success!"
	@rm -rf out out.asm

decode/challenge: asm
	@echo ">> challenge <<"
	@zig build dumpdecode -- asm/challenge_movs > out.asm
	@echo "comparing results..."
	@nasm out.asm
	@diff out asm/challenge_movs
	@echo "success!"
	@rm -rf out out.asm

decode/add_sub_cmp_jnz: asm
	@echo ">> add_sub_cmp_jnz <<"
	@zig build dumpdecode -- asm/add_sub_cmp_jnz > out.asm
	@echo "comparing results..."
	@nasm out.asm
	@diff out asm/add_sub_cmp_jnz
	@echo "success!"
	@rm -rf out out.asm

test:
	zig build test

clean:
	rm -rf out out.asm

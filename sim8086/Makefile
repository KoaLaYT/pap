.PHONY: asm decode/single decode/many

all: decode/single decode/many decode/more decode/challenge

asm:
	@nasm single_register_mov.asm
	@nasm many_register_mov.asm
	@nasm more_movs.asm
	@nasm challenge_movs.asm

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

clean:
	rm -rf out out.asm

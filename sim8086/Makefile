.PHONY: asm decode/single decode/many

asm: single_register_mov.asm many_register_mov.asm
	@echo "preparing bin file..."
	@nasm single_register_mov.asm
	@nasm many_register_mov.asm

decode/single: asm
	@echo "decode bin file..."
	@zig build run -- single_register_mov > out.asm
	@echo "comparing results..."
	@nasm out.asm
	@diff out single_register_mov
	@echo "success!"
	@rm -rf out out.asm

decode/many: asm
	@echo "decode bin file..."
	@zig build run -- many_register_mov > out.asm
	@echo "comparing results..."
	@nasm out.asm
	@diff out many_register_mov
	@echo "success!"
	@rm -rf out out.asm

clean:
	rm -rf out out.asm

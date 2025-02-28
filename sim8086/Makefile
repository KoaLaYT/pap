ASMS := $(shell find ./asm -maxdepth 1 -mindepth 1 -name "*.asm")
DISASMS := $(ASMS:./asm/%.asm=%)
DECODES := $(DISASMS:%=decode/%)

test:
	zig build test

asm/%: asm/%.asm
	@nasm $<

decode: $(DECODES)

define decode_template =
decode/$(1): asm/$(1)
	@echo ">> $(1) <<"
	@zig build dumpdecode -- $$< > out.asm
	@echo "comparing results..."
	@nasm out.asm
	@diff out $$<
	@echo "success!"
	@rm -rf out out.asm

endef

$(foreach bin,$(DISASMS),$(eval $(call decode_template,$(bin))))

clean:
	rm -rf out out.asm

.PHONY: cal gen clean

clean:
	@rm -rf *_flex.json *_answer.f64

cal:
	@go run ./cmd/cal

gen:
	@go run ./cmd/gen -seed 123 -size 10000

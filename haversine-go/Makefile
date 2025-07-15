.PHONY: cal gen clean

clean:
	@rm -rf *_flex.json *_answer.f64

cal:
	@go run ./cmd/cal -json data_10000000_flex.json -bin data_10000000_answer.f64

gen:
	@go run ./cmd/gen -cluster -seed 428995 -size 10000000

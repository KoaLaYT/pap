# Performance-Aware Programming

Course link: [Computer, Enhance!](https://www.computerenhance.com/p/table-of-contents)

### 1. Haversine

init go version:

```bash
cd haversine-go
go run ./cmd/cal

Result: 10006.813489
Input = 8.583941 seconds
Math = 1.133882 seconds
Total = 9.717823 seconds
Throughput = 1029037.098730 haversines/second
```

init zig version:

```bash
cd haversine-zig
zig build -Doptimize=ReleaseFast run

Result: 10006.813489
Input = 3.012565 seconds
Math = 0.288343 seconds
Total = 3.300908 seconds
Throughput = 3029469.772806 haversines/second
```

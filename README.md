# Performance-Aware Programming

Course link: [Computer, Enhance!](https://www.computerenhance.com/p/table-of-contents)

### 1. Haversine

init python version (Casey's origin):

```bash
$ cd haversine-python
$ python3 main.py

Result: 10006.813489406335
Input = 5.872759103775024 seconds
Math = 5.376621961593628 seconds
Total = 11.249381065368652 seconds
Throughput = 888937.7950565754 haversines/second
```

init go version:

```bash
$ cd haversine-go
$ go run ./cmd/cal

Result: 10006.813489
Input = 8.583941 seconds
Math = 1.133882 seconds
Total = 9.717823 seconds
Throughput = 1029037.098730 haversines/second
```

init zig version:

```bash
$ cd haversine-zig
$ zig build -Doptimize=ReleaseFast run

Result: 10006.813489
Input = 3.012565 seconds
Math = 0.288343 seconds
Total = 3.300908 seconds
Throughput = 3029469.772806 haversines/second
```

### 2. Sim 8086

prerequisite:

1. [intel 8086 manual](https://edge.edx.org/c4x/BITSPilani/EEE231/asset/8086_family_Users_Manual_1_.pdf)

2. `nasm`: assembler for 8086 [download](https://www.nasm.us/pub/nasm/releasebuilds/2.16.03/macosx/)


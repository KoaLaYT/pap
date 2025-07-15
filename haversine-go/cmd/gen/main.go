package main

import (
	"bufio"
	"encoding/binary"
	"flag"
	"fmt"
	"koalayt/haversine-go/reference"
	"math"
	"math/rand"
	"os"
)

const EarchRadius float64 = 6372.8

type Rand struct {
	r *rand.Rand
}

func NewRand(seed int64) Rand {
	return Rand{
		r: rand.New(rand.NewSource(seed)),
	}
}

// [min, max)
func (r Rand) F64(min, max float64) float64 {
	f := r.r.Float64() // [0.0, 1.0)
	return min + f*(max-min)
}

func must(err error) {
	if err != nil {
		panic(err)
	}
}

func must2[T any](r T, err error) T {
	if err != nil {
		panic(err)
	}
	return r
}

func parseArgs() (seed int64, size int, isCluster bool) {
	flag.Int64Var(&seed, "seed", 0, "seed, default 0")
	flag.IntVar(&size, "size", 0, "size, must larger than 0")
	flag.BoolVar(&isCluster, "cluster", false, "generate by cluster, default is uniform")
	flag.Parse()

	if size <= 0 {
		flag.Usage()
		os.Exit(1)
	}

	return
}

func main() {
	seed, size, isCluster := parseArgs()

	rand := NewRand(seed)

	clusterCountLeft := math.MaxInt
	if isCluster {
		clusterCountLeft = 0
	}

	jsonFilename := fmt.Sprintf("data_%d_flex.json", size)
	binFilename := fmt.Sprintf("data_%d_answer.f64", size)

	jsonFile := must2(os.OpenFile(jsonFilename, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, 0o644))
	defer jsonFile.Close()
	binFile := must2(os.OpenFile(binFilename, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, 0o644))
	defer binFile.Close()

	jsonWriter := bufio.NewWriter(jsonFile)
	binWriter := bufio.NewWriter(binFile)

	xCenter := 0.0
	yCenter := 0.0
	xRadius := 180.0
	yRadius := 90.0
	xMin := -180.0
	xMax := 180.0
	yMin := -90.0
	yMax := 90.0
	total := 0.0

	jsonWriter.WriteString("{\"pairs\":[\n")

	for i := 0; i < size; i++ {
		if clusterCountLeft == 0 {
			clusterCountLeft = 1 + size/64
			xCenter = rand.F64(-180, 180)
			yCenter = rand.F64(-90, 90)
			xRadius = rand.F64(0, 180)
			yRadius = rand.F64(0, 90)
			xMin = max(xCenter-xRadius, -180)
			xMax = min(xCenter+xRadius, 180)
			yMin = max(yCenter-yRadius, -90)
			yMax = min(yCenter+yRadius, 90)
		}
		clusterCountLeft -= 1

		x0 := rand.F64(xMin, xMax)
		y0 := rand.F64(yMin, yMax)
		x1 := rand.F64(xMin, xMax)
		y1 := rand.F64(yMin, yMax)

		anwser := reference.Haversine(x0, y0, x1, y1, EarchRadius)
		total += anwser

		_ = must2(jsonWriter.WriteString(fmt.Sprintf("    {\"x0\":%.9f, \"y0\":%.9f, \"x1\":%.9f, \"y1\":%.9f}", x0, y0, x1, y1)))
		if i < size-1 {
			_ = must2(jsonWriter.WriteString(",\n"))
		} else {
			must(jsonWriter.WriteByte('\n'))
		}
		must(binary.Write(binWriter, binary.LittleEndian, anwser))
	}

	must2(jsonWriter.WriteString("]}"))
	must(jsonWriter.Flush())

	avg := total / float64(size)
	must(binary.Write(binWriter, binary.LittleEndian, avg))
	must(binWriter.Flush())

	var method = "Uniform"
	if isCluster {
		method = "Cluster"
	}
	fmt.Printf("Method: %s\n", method)
	fmt.Printf("Random seed: %d\n", seed)
	fmt.Printf("Pair count: %d\n", size)
	fmt.Printf("Expected sum: %.6f\n", avg)
}

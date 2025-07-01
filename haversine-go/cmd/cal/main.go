package main

import (
	"encoding/json"
	"fmt"
	"koalayt/haversine-go/reference"
	"os"
	"time"
)

const EarchRadius float64 = 6372.8

type Pair struct {
	X0 float64 `json:"x0"`
	Y0 float64 `json:"y0"`
	X1 float64 `json:"x1"`
	Y1 float64 `json:"y1"`
}

func (p Pair) haversineDistance() float64 {
	return reference.Haversine(p.X0, p.Y0, p.X1, p.Y1, EarchRadius)
}

type Data struct {
	Pairs []Pair `json:"pairs"`
}

// 1 to 1 copy from casey's python version
func main() {
	f := must2(os.Open("data.json"))
	defer f.Close()

	startTime := time.Now()
	var data Data
	dec := json.NewDecoder(f)
	must(dec.Decode(&data))
	midTime := time.Now()

	sum := 0.0
	count := 0
	for _, pair := range data.Pairs {
		sum += pair.haversineDistance()
		count += 1
	}
	avg := sum / float64(count)
	endTime := time.Now()

	fmt.Printf("Result: %.6f\n", avg)
	fmt.Printf("Input = %.6f seconds\n", midTime.Sub(startTime).Seconds())
	fmt.Printf("Math = %.6f seconds\n", endTime.Sub(midTime).Seconds())
	fmt.Printf("Total = %.6f seconds\n", endTime.Sub(startTime).Seconds())
	fmt.Printf("Throughput = %.6f haversines/second\n", float64(count)/endTime.Sub(startTime).Seconds())
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

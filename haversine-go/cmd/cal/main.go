package main

import (
	"encoding/json"
	"fmt"
	"math"
	"os"
	"time"
)

const EarchRadius float64 = 6371.0

type Pair struct {
	X0 float64 `json:"x0"`
	Y0 float64 `json:"y0"`
	X1 float64 `json:"x1"`
	Y1 float64 `json:"y1"`
}

func radian(degree float64) float64 {
	return degree * math.Pi / 180.0
}

// https://en.wikipedia.org/wiki/Haversine_formula
func (p Pair) haversineDistance() float64 {
	dy := radian(p.Y1 - p.Y0)
	dx := radian(p.X1 - p.X0)
	y0 := radian(p.Y0)
	y1 := radian(p.Y1)

	rootTerm := math.Pow(math.Sin(dy/2), 2) + math.Cos(y0)*math.Cos(y1)*math.Pow(math.Sin(dx/2), 2)
	return 2 * EarchRadius * math.Asin(math.Sqrt(rootTerm))
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

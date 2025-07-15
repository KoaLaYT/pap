package main

import (
	"encoding/binary"
	"flag"
	"fmt"
	"io"
	"koalayt/haversine-go/dumbjson"
	"koalayt/haversine-go/reference"
	"math"
	"os"
	"reflect"
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

func decodePairs(r io.Reader) ([]Pair, error) {
	parser, err := dumbjson.NewParser(r)
	if err != nil {
		return nil, err
	}

	json, err := parser.Parse()
	if err != nil {
		return nil, err
	}

	var pairs []Pair
	obj := json.(dumbjson.ObjectNode)
	jsonPairs := obj.Value["pairs"].(dumbjson.ArrayNode)
	for _, jsonPair := range jsonPairs.Value {
		pair := jsonPair.(dumbjson.ObjectNode)
		x0 := pair.Value["x0"].(dumbjson.NumberNode).Value
		y0 := pair.Value["y0"].(dumbjson.NumberNode).Value
		x1 := pair.Value["x1"].(dumbjson.NumberNode).Value
		y1 := pair.Value["y1"].(dumbjson.NumberNode).Value
		pairs = append(pairs, Pair{x0, y0, x1, y1})
	}

	return pairs, nil
}

func parseArgs() (jsonfile, binfile string) {
	flag.StringVar(&jsonfile, "json", "", "required, json file to do calculation")
	flag.StringVar(&binfile, "bin", "", "optional, binary file to do verification")
	flag.Parse()

	return jsonfile, binfile
}

func isNilish(val any) bool {
	if val == nil {
		return true
	}

	v := reflect.ValueOf(val)
	k := v.Kind()
	switch k {
	case reflect.Chan, reflect.Func, reflect.Map, reflect.Pointer,
		reflect.UnsafePointer, reflect.Interface, reflect.Slice:
		return v.IsNil()
	}

	return false
}

func almostEqual(r io.Reader, got float64) {
	if isNilish(r) {
		return
	}

	var answer float64
	must(binary.Read(r, binary.LittleEndian, &answer))
	if math.Abs(got-answer) > 1e-6 {
		panic(fmt.Errorf("expect %v, got %v", answer, got))
	}
}

func main() {
	jsonfile, binfile := parseArgs()

	if jsonfile == "" {
		flag.Usage()
		os.Exit(1)
	}

	_ = binfile

	jf := must2(os.Open(jsonfile))
	defer jf.Close()

	var bf *os.File
	if binfile != "" {
		bf = must2(os.Open(binfile))
		defer bf.Close()
	}

	startTime := time.Now()
	pairs := must2(decodePairs(jf))
	midTime := time.Now()

	sum := 0.0
	count := 0
	for _, pair := range pairs {
		v := pair.haversineDistance()
		almostEqual(bf, v)
		sum += v
		count += 1
	}
	avg := sum / float64(count)
	almostEqual(bf, avg)
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

package main

import (
	"bufio"
	"fmt"
	"math/rand"
	"os"
)

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

// [-90, 90)
func randLatitude() float32 {
	return rand.Float32()*180.0 - 90.0
}

// [-180, 180)
func randLongitude() float32 {
	return rand.Float32()*360.0 - 180.0
}

func main() {
	f := must2(os.OpenFile("data.json", os.O_CREATE|os.O_TRUNC|os.O_WRONLY, 0o644))
	defer f.Close()

	w := bufio.NewWriter(f)
	w.WriteString("{\"pairs\":[\n")

	amount := 10_000_000
	for i := 0; i < amount; i++ {
		x0 := randLongitude()
		y0 := randLatitude()
		x1 := randLongitude()
		y1 := randLatitude()

		_ = must2(w.WriteString(fmt.Sprintf("    {\"x0\":%.6f, \"y0\":%.6f, \"x1\":%.6f, \"y1\":%.6f}", x0, y0, x1, y1)))
		if i < amount-1 {
			_ = must2(w.WriteString(",\n"))
		} else {
			must(w.WriteByte('\n'))
		}
	}

	must2(w.WriteString("]}"))
	must(w.Flush())
}

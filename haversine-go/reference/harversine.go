package reference

import "math"

// reference implementation
// https://github.com/cmuratori/computer_enhance/blob/main/perfaware/part2/listing_0065_haversine_formula.cpp
func Haversine(x0, y0, x1, y1, earthRadius float64) float64 {
	dLat := radian(y1 - y0)
	dLon := radian(x1 - x0)
	lat1 := radian(y0)
	lat2 := radian(y1)

	a := square(sin(dLat/2.0)) + cos(lat1)*cos(lat2)*square(sin(dLon/2))
	c := 2.0 * asin(sqrt(a))

	return earthRadius * c
}

func sin(v float64) float64 {
	return math.Sin(v)
}

func cos(v float64) float64 {
	return math.Cos(v)
}

func asin(v float64) float64 {
	return math.Asin(v)
}

func sqrt(v float64) float64 {
	return math.Sqrt(v)
}

func square(v float64) float64 {
	return v * v
}

func radian(degree float64) float64 {
	return degree * math.Pi / 180.0
}

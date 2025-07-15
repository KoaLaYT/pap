package dumbjson_test

import (
	"koalayt/haversine-go/dumbjson"
	"math"
	"testing"
)

func TestFloatConv(t *testing.T) {
	type TestCase struct {
		input  string
		expect float64
	}
	testCases := []TestCase{
		{input: "123.34", expect: 123.34},
		{input: "-123.34", expect: -123.34},
		{input: "-0.34", expect: -0.34},
		{input: "0.002", expect: 0.002},
	}

	for _, tt := range testCases {
		got := dumbjson.FloatConv(tt.input)
		if math.Abs(got-tt.expect) > 1e-9 {
			t.Errorf("parse %s, expect %v, got %v\n",
				tt.input, tt.expect, got)
		}
	}
}

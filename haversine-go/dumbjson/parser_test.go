package dumbjson_test

import (
	"bytes"
	"koalayt/haversine-go/dumbjson"
	"testing"
)

func TestParser_basic(t *testing.T) {
	t.Parallel()

	var buf bytes.Buffer
	buf.WriteString(`{"hello": "world"}`)

	p, err := dumbjson.NewParser(&buf)
	if err != nil {
		t.Error(err)
	}

	json, err := p.Parse()
	if err != nil {
		t.Error(err)
	}

	if json.Type() != "Object" {
		t.Errorf("Expect ObjectNode, got %q", json.Type())
	}

	obj := json.(dumbjson.ObjectNode)
	if len(obj.Value) != 1 {
		t.Errorf("Expect object has 1 key, got %d keys", len(obj.Value))
	}

	v, got := obj.Value["hello"]
	if !got {
		t.Error("Expect key `hello`")
	}
	if v.Type() != "String" {
		t.Errorf("Expect StringNode, got %q", v.Type())
	}

	vv := v.(dumbjson.StringNode)
	if vv.Value != "world" {
		t.Errorf("Expect StringNode as `world`, got %q", vv.Value)
	}
}

func TestParser_pairs(t *testing.T) {
	t.Parallel()

	var buf bytes.Buffer
	buf.WriteString(`
	{"pairs":[
		{"x0":-140.956195, "y0":-85.010687, "x1":-136.088660, "y1":-82.266397},
		{"x0":46.781777, "y0":76.594807, "x1":97.042218, "y1":77.936222},
		{"x0":-15.109535, "y0":-52.015009, "x1":-27.701099, "y1":-44.873940},
		{"x0":0.069828, "y0":44.224182, "x1":121.549765, "y1":44.951483},
		{"x0":50.183254, "y0":21.099407, "x1":52.369989, "y1":9.382464}
	]}
	`)

	p, err := dumbjson.NewParser(&buf)
	if err != nil {
		t.Fatal(err)
	}

	json, err := p.Parse()
	if err != nil {
		t.Fatal(err)
	}

	obj, ok := json.(dumbjson.ObjectNode)
	if !ok {
		t.Errorf("Expect ObjectNode")
	}
	arr, ok := obj.Value["pairs"].(dumbjson.ArrayNode)
	if !ok {
		t.Errorf("Expect ArrayNode")
	}
	if len(arr.Value) != 5 {
		t.Errorf("Expect ArrayNode has 5 elements, got %d", len(arr.Value))
	}
}

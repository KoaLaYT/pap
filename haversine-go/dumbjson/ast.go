package dumbjson

type JSONNode interface {
	Type() string
}

type ObjectNode struct {
	Value map[string]JSONNode
}

func (n ObjectNode) Type() string { return "Object" }

type ArrayNode struct {
	Value []JSONNode
}

func (n ArrayNode) Type() string { return "Array" }

type StringNode struct {
	Value string
}

func (n StringNode) Type() string { return "String" }

type NumberNode struct {
	Value float64
}

func (n NumberNode) Type() string { return "Number" }

type BooleanNode struct {
	Value bool
}

func (n BooleanNode) Type() string { return "Boolean" }

type NullNode struct{}

func (n NullNode) Type() string { return "Null" }

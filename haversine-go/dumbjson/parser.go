package dumbjson

import (
	"fmt"
	"io"
)

type TokenType int

const (
	TokenEOF TokenType = iota
	// TokenError

	TokenOpenBrace
	TokenEndBrace

	TokenOpenBracket
	TokenEndBracket

	TokenComma
	TokenColon

	TokenStringLiteral
	TokenNumber
	TokenTrue
	TokenFalse
	TokenNull
)

func (tt TokenType) String() string {
	switch tt {
	case TokenEOF:
		return "EOF"
	// case TokenError:
	// 	return "Error"
	case TokenOpenBrace:
		return "{"
	case TokenEndBrace:
		return "}"
	case TokenOpenBracket:
		return "["
	case TokenEndBracket:
		return "]"
	case TokenComma:
		return ","
	case TokenColon:
		return ":"
	case TokenStringLiteral:
		return "StringLiteral"
	case TokenNumber:
		return "Number"
	case TokenTrue:
		return "True"
	case TokenFalse:
		return "False"
	case TokenNull:
		return "Null"
	default:
		return "Unknown"
	}
}

type Token struct {
	Type  TokenType
	Value string
}

func (t Token) String() string {
	return fmt.Sprintf("Token %q = %s", t.Type, string(t.Value))
}

// To make it simple, we read whole json into memory and do parse
type Parser struct {
	buf []byte
	at  int
}

func NewParser(r io.Reader) (*Parser, error) {
	buf, err := io.ReadAll(r)
	if err != nil {
		return nil, err
	}

	return &Parser{buf: buf, at: 0}, nil
}

func (p *Parser) Parse() (JSONNode, error) {
	return p.parseJSON()
}

func (p *Parser) parseJSON() (JSONNode, error) {
	tok, err := p.nextToken()
	if err != nil {
		return nil, err
	}

	switch tok.Type {
	case TokenOpenBrace:
		return p.parseObject()
	case TokenOpenBracket:
		return p.parseArray()
	case TokenStringLiteral:
		return StringNode{Value: string(tok.Value)}, nil
	case TokenNumber:
		v := FloatConv(tok.Value)
		return NumberNode{Value: v}, nil
	case TokenTrue:
		return BooleanNode{Value: true}, nil
	case TokenFalse:
		return BooleanNode{Value: false}, nil
	case TokenNull:
		return NullNode{}, nil
	default:
		return nil, fmt.Errorf("Bad %v at %d", tok, p.at)
	}
}

func (p *Parser) parseObject() (JSONNode, error) {
	object := ObjectNode{
		Value: make(map[string]JSONNode),
	}

	for {
		// label
		labelTok, err := p.nextToken()
		if err != nil {
			return nil, err
		}
		if labelTok.Type != TokenStringLiteral {
			return nil, fmt.Errorf("Expect string literal, got %v", labelTok)
		}

		// :
		colonTok, err := p.nextToken()
		if err != nil {
			return nil, err
		}
		if colonTok.Type != TokenColon {
			return nil, fmt.Errorf("Expect `:`, got %v", colonTok)
		}

		// value
		value, err := p.parseJSON()
		if err != nil {
			return nil, err
		}
		object.Value[string(labelTok.Value)] = value

		hasMore, err := p.checkCloingToken(TokenEndBrace)
		if err != nil {
			return nil, err
		}
		if !hasMore {
			break
		}
	}

	return object, nil
}

func (p *Parser) parseArray() (JSONNode, error) {
	array := ArrayNode{
		Value: make([]JSONNode, 0),
	}

	for {
		element, err := p.parseJSON()
		if err != nil {
			return nil, err
		}
		array.Value = append(array.Value, element)

		hasMore, err := p.checkCloingToken(TokenEndBracket)
		if err != nil {
			return nil, err
		}
		if !hasMore {
			break
		}
	}

	return array, nil
}

func (p *Parser) checkCloingToken(closingType TokenType) (hasMore bool, err error) {
	tok, err := p.nextToken()
	if err != nil {
		return false, err
	}
	switch tok.Type {
	case TokenComma:
		return true, nil
	case closingType:
		return false, nil
	default:
		return false, fmt.Errorf("Expect `,` or %v, got %v", closingType, tok)
	}
}

func (p *Parser) skipWhitespace() {
	for p.at < len(p.buf) {
		b := p.buf[p.at]
		if b == ' ' || b == '\n' || b == '\t' {
			p.at += 1
		} else {
			break
		}
	}
}

func (p *Parser) nextKeyword(typ TokenType, keyword string) (Token, error) {
	s := p.at
	for i := 0; i < len(keyword); i += 1 {
		if p.buf[p.at] != keyword[i] {
			return Token{}, fmt.Errorf("Expect %s, got %s", keyword, string(p.buf[s:p.at+1]))
		}
		p.at += 1
	}
	return Token{Type: typ}, nil
}

func (p *Parser) nextStringLiteral() (Token, error) {
	s := p.at
	p.at += 1
	for p.at < len(p.buf) && p.buf[p.at] != '"' {
		p.at += 1
	}
	if p.at >= len(p.buf) {
		return Token{}, fmt.Errorf(`Expect closing double quote, but find EOF`)
	}
	p.at += 1
	return Token{
		Type:  TokenStringLiteral,
		Value: string(p.buf[s+1 : p.at-1]), // remove closing " "
	}, nil
}

func (p *Parser) nextNumber() (Token, error) {
	s := p.at
	dots := 0

	if p.buf[p.at] == '-' {
		p.at += 1
	}

	for p.at < len(p.buf) {
		b := p.buf[p.at]
		if b >= '0' && b <= '9' {
			p.at += 1
		} else if b == '.' {
			dots += 1
			if dots > 1 {
				return Token{}, fmt.Errorf(`Expect at most one dot, but got 2 dots`)
			}
			p.at += 1
		} else {
			break
		}
	}

	return Token{Type: TokenNumber, Value: string(p.buf[s:p.at])}, nil
}

func (p *Parser) nextToken() (Token, error) {
	p.skipWhitespace()

	if p.at >= len(p.buf) {
		return Token{Type: TokenEOF}, nil
	}

	b := p.buf[p.at]
	switch b {
	case '{':
		p.at += 1
		return Token{Type: TokenOpenBrace}, nil
	case '}':
		p.at += 1
		return Token{Type: TokenEndBrace}, nil
	case '[':
		p.at += 1
		return Token{Type: TokenOpenBracket}, nil
	case ']':
		p.at += 1
		return Token{Type: TokenEndBracket}, nil
	case ',':
		p.at += 1
		return Token{Type: TokenComma}, nil
	case ':':
		p.at += 1
		return Token{Type: TokenColon}, nil
	case '"':
		return p.nextStringLiteral()
	case '-', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9':
		return p.nextNumber()
	case 't':
		return p.nextKeyword(TokenTrue, "true")
	case 'f':
		return p.nextKeyword(TokenFalse, "false")
	case 'n':
		return p.nextKeyword(TokenNull, "null")
	}

	return Token{}, fmt.Errorf(`Unknown byte %c at %d`, b, p.at)
}

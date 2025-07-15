package dumbjson

func FloatConv(s string) float64 {
	var f float64 = 0.0
	base := 10.0
	sign := 1.0

	for i := 0; i < len(s); i++ {
		b := s[i]

		switch b {
		case '-':
			sign = -1
		case '.':
			base = 1
		case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9':
			v := float64(b - '0')
			if base > 1 {
				f = base*f + v
			} else {
				base /= 10
				f += v * base
			}
		default:
			return 0.0
		}
	}

	return f * sign
}

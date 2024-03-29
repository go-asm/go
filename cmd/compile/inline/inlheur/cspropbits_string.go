// Code generated by "stringer -bitset -type CSPropBits"; DO NOT EDIT.

package inlheur

import (
	"bytes"
	"strconv"
)

func _() {
	// An "invalid array index" compiler error signifies that the constant values have changed.
	// Re-run the stringer command to generate them again.
	var x [1]struct{}
	_ = x[CallSiteInLoop-1]
	_ = x[CallSiteOnPanicPath-2]
	_ = x[CallSiteInInitFunc-4]
}

var _CSPropBits_value = [...]uint64{
	0x1, /* CallSiteInLoop */
	0x2, /* CallSiteOnPanicPath */
	0x4, /* CallSiteInInitFunc */
}

const _CSPropBits_name = "CallSiteInLoopCallSiteOnPanicPathCallSiteInInitFunc"

var _CSPropBits_index = [...]uint8{0, 14, 33, 51}

func (i CSPropBits) String() string {
	var b bytes.Buffer

	remain := uint64(i)
	seen := false

	for k, v := range _CSPropBits_value {
		x := _CSPropBits_name[_CSPropBits_index[k]:_CSPropBits_index[k+1]]
		if v == 0 {
			if i == 0 {
				b.WriteString(x)
				return b.String()
			}
			continue
		}
		if (v & remain) == v {
			remain &^= v
			x := _CSPropBits_name[_CSPropBits_index[k]:_CSPropBits_index[k+1]]
			if seen {
				b.WriteString("|")
			}
			seen = true
			b.WriteString(x)
		}
	}
	if remain == 0 {
		return b.String()
	}
	return "CSPropBits(0x" + strconv.FormatInt(int64(i), 16) + ")"
}

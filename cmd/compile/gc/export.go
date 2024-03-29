// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package gc

import (
	"fmt"
	"go/constant"

	"github.com/go-asm/go/cmd/bio"
	"github.com/go-asm/go/cmd/compile/base"
	"github.com/go-asm/go/cmd/compile/ir"
	"github.com/go-asm/go/cmd/compile/typecheck"
	"github.com/go-asm/go/cmd/compile/types"
)

func dumpasmhdr() {
	b, err := bio.Create(base.Flag.AsmHdr)
	if err != nil {
		base.Fatalf("%v", err)
	}
	fmt.Fprintf(b, "// generated by compile -asmhdr from package %s\n\n", types.LocalPkg.Name)
	for _, n := range typecheck.Target.AsmHdrDecls {
		if n.Sym().IsBlank() {
			continue
		}
		switch n.Op() {
		case ir.OLITERAL:
			t := n.Val().Kind()
			if t == constant.Float || t == constant.Complex {
				break
			}
			fmt.Fprintf(b, "#define const_%s %v\n", n.Sym().Name, n.Val().ExactString())

		case ir.OTYPE:
			t := n.Type()
			if !t.IsStruct() || t.StructType().Map != nil || t.IsFuncArgStruct() {
				break
			}
			fmt.Fprintf(b, "#define %s__size %d\n", n.Sym().Name, int(t.Size()))
			for _, f := range t.Fields() {
				if !f.Sym.IsBlank() {
					fmt.Fprintf(b, "#define %s_%s %d\n", n.Sym().Name, f.Sym.Name, int(f.Offset))
				}
			}
		}
	}

	b.Close()
}

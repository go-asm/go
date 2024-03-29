// Copyright 2020 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package fix

func init() {
	addTestCases(buildtagTests, buildtag)
}

var buildtagTests = []testCase{
	{
		Name:    "buildtag.oldGo",
		Version: 1_10,
		In: `//go:build yes
// +build yes

package fix
`,
	},
	{
		Name:    "buildtag.new",
		Version: 1_99,
		In: `//go:build yes
// +build yes

package fix
`,
		Out: `//go:build yes

package fix
`,
	},
}

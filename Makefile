.DEFAULT_GOAL = all

GO_VERSION ?= 1.22.4

.PHONY: all
all: sync remove fix fmt tidy check commit

define ditto
ditto ${GO_SRC}/${1} ${2}
sed -i 's|package main|package $(shell basename ${2})|' ${2}/*.go || true
endef

.PHONY: sync
sync:
	go run golang.org/dl/go${GO_VERSION}@latest download
	rm -rf $(shell find . -mindepth 1 -maxdepth 1 -type d -not -iwholename '**.git**' -not -iwholename '**_**' -not -iwholename '**assembler**' | sort)
	$(call ditto,${HOME}/sdk/go${GO_VERSION}/src/internal,.)
	$(call ditto,${HOME}/sdk/go${GO_VERSION}/src/cmd/internal,./cmd)
	$(call ditto,${HOME}/sdk/go${GO_VERSION}/src/cmd/api,./cmd/api)
	$(call ditto,${HOME}/sdk/go${GO_VERSION}/src/cmd/asm/internal,./cmd/asm)
	$(call ditto,${HOME}/sdk/go${GO_VERSION}/src/cmd/cgo,./cmd/cgo)
	$(call ditto,${HOME}/sdk/go${GO_VERSION}/src/cmd/compile/internal,./cmd/compile)
	$(call ditto,${HOME}/sdk/go${GO_VERSION}/src/cmd/covdata,./cmd/covdata)
	$(call ditto,${HOME}/sdk/go${GO_VERSION}/src/cmd/dist,./cmd/dist)
	$(call ditto,${HOME}/sdk/go${GO_VERSION}/src/cmd/doc,./cmd/doc)
	$(call ditto,${HOME}/sdk/go${GO_VERSION}/src/cmd/fix,./cmd/fix)
	$(call ditto,${HOME}/sdk/go${GO_VERSION}/src/cmd/go/internal,./cmd/go)
	$(call ditto,${HOME}/sdk/go${GO_VERSION}/src/cmd/gofmt,./cmd/gofmt)
	$(call ditto,${HOME}/sdk/go${GO_VERSION}/src/cmd/link/internal,./cmd/link)
	$(call ditto,${HOME}/sdk/go${GO_VERSION}/src/cmd/nm,./cmd/nm)
	$(call ditto,${HOME}/sdk/go${GO_VERSION}/src/cmd/objdump,./cmd/objdump)
	$(call ditto,${HOME}/sdk/go${GO_VERSION}/src/cmd/pack,./cmd/pack)
	$(call ditto,${HOME}/sdk/go${GO_VERSION}/src/cmd/pprof,./cmd/pprof)
	$(call ditto,${HOME}/sdk/go${GO_VERSION}/src/cmd/trace,./cmd/trace)

.PHONY: remove
remove:
	rm -f  abi/abi_test.go abi/abi_test.s abi/export_test.go
	rm -f  bytealg/compare_amd64.s bytealg/compare_arm64.s bytealg/equal_amd64.s bytealg/equal_arm64.s
	rm -fr cmd/cgo/internal/test/ cmd/cgo/internal cmd/cgo/internal/testcarchive/
	rm -f  cmd/covdata/tool_test.go
	rm -f  fuzz/trace.go
	rm -f  syscall/unix/getentropy_darwin.go syscall/unix/pty_darwin.go syscall/unix/user_darwin.go syscall/unix/net_darwin.go testpty/pty_darwin.go

define fix_linkname
sed -i -E ':a;N;$$!ba;s|${1}|${2}|' ${3}
endef

.PHONY: fix
fix: fix/linkname fix/import
	sed -i -E 's|!(darwin)|\1|' testpty/pty_none.go

.PHONY: fix/linkname
fix/linkname:
	$(call fix_linkname,(//go:noescape)\n(func Compare),\1\n//go:linkname Compare internal/bytealg.Compare\n\2,bytealg/compare_native.go)
	$(call fix_linkname,import "sync/atomic",import (\n	"sync/atomic"\n	_ "unsafe" // for go:linkname\n),poll/fd_mutex.go)
	$(call fix_linkname,\n(func runtime_Semacquire),\n\n//go:linkname runtime_Semacquire runtime.semacquire\n\1,poll/fd_mutex.go)
	$(call fix_linkname,(func runtime_Semrelease),//go:linkname runtime_Semrelease runtime.semrelease\n\1,poll/fd_mutex.go)
	$(call fix_linkname,\n(func runtime_pollServerInit),//go:linkname runtime_pollServerInit runtime.pollServerInit\n\1,poll/fd_poll_runtime.go)
	$(call fix_linkname,\n(func runtime_pollOpen),\n//go:linkname runtime_pollOpen runtime.pollOpen\n\1,poll/fd_poll_runtime.go)
	$(call fix_linkname,\n(func runtime_pollClose),\n//go:linkname runtime_pollClose runtime.pollClose\n\1,poll/fd_poll_runtime.go)
	$(call fix_linkname,\n(func runtime_pollWait),\n//go:linkname runtime_pollWait runtime.pollWait\n\1,poll/fd_poll_runtime.go)
	$(call fix_linkname,\n(func runtime_pollWaitCanceled),\n//go:linkname runtime_pollWaitCanceled runtime.pollWaitCanceled\n\1,poll/fd_poll_runtime.go)
	$(call fix_linkname,\n(func runtime_pollReset),\n//go:linkname runtime_pollReset runtime.pollReset\n\1,poll/fd_poll_runtime.go)
	$(call fix_linkname,\n(func runtime_pollSetDeadline),\n//go:linkname runtime_pollSetDeadline runtime.pollSetDeadline\n\1,poll/fd_poll_runtime.go)
	$(call fix_linkname,\n(func runtime_pollUnblock),\n//go:linkname runtime_pollUnblock runtime.pollUnblock\n\1,poll/fd_poll_runtime.go)
	$(call fix_linkname,\n(func runtime_isPollServerDescriptor),\n//go:linkname runtime_isPollServerDescriptor runtime.isPollServerDescriptor\n\1,poll/fd_poll_runtime.go)
	sed -i -E ':a;N;$$!ba;s|func resolveNameOff\(ptrInModule unsafe.Pointer, off int32\) unsafe.Pointer|//go:linkname resolveNameOff internal/reflectlite.resolveTypeOff\nfunc resolveNameOff\(ptrInModule unsafe.Pointer, off int32\) unsafe.Pointer|' reflectlite/type.go
	sed -i -E ':a;N;$$!ba;s|func resolveTypeOff\(rtype unsafe.Pointer, off int32\) unsafe.Pointer|//go:linkname resolveTypeOff internal/reflectlite.resolveTypeOff\nfunc resolveTypeOff\(rtype unsafe.Pointer, off int32\) unsafe.Pointer|' reflectlite/type.go
	sed -i -E ':a;N;$$!ba;s|// implemented in package runtime\nfunc unsafe_New\(\*rtype\) unsafe.Pointer|// implemented in package runtime\n//go:linkname unsafe_New internal/reflectlite.unsafe_New\nfunc unsafe_New\(\*rtype\) unsafe.Pointer|' reflectlite/value.go
	sed -i -E ':a;N;$$!ba;s|func ifaceE2I\(t \*rtype, src any, dst unsafe.Pointer\)|//go:linkname ifaceE2I internal/reflectlite.ifaceE2I\nfunc ifaceE2I\(t \*rtype, src any, dst unsafe.Pointer\)|' reflectlite/value.go
	sed -i -E ':a;N;$$!ba;s|func typedmemmove\(t \*rtype, dst, src unsafe.Pointer\)|//go:linkname typedmemmove internal/reflectlite.typedmemmove\nfunc typedmemmove\(t \*rtype, dst, src unsafe.Pointer\)|' reflectlite/value.go
	sed -i -E 's|block<ABIInternal>|block|g' chacha8rand/chacha8_amd64.s

.PHONY: fix/import
fix/import:
	grep -rl 'cmd/internal/' ${CURDIR}/** | grep -v Makefile | xargs sed -i 's|cmd/internal/|github.com/go-asm/go/cmd/|g'
	grep -rl 'internal/' ${CURDIR}/** | grep -v Makefile | xargs sed -i 's|internal/|github.com/go-asm/go/|g'
	grep -rl 'cmd/.*/github.com/go-asm' ${CURDIR}/** | grep -v -e Makefile | xargs sed -i -E 's|cmd/(.*)/github.com/go-asm/go|github.com/go-asm/go/cmd/\1|g'
	grep -rl 'github.com/go-asm/go/cmd/go/github.com/go-asm/go' ${CURDIR}/** | grep -v -e Makefile | xargs sed -i -E 's|github.com/go-asm/go/cmd/go/github.com/go-asm/go|github.com/go-asm/go/cmd/go|g'
	grep -rl 'github.com/go-asm/go/cmd/go/lockedfile/filelock' ${CURDIR}/** | grep -v -e Makefile | xargs sed -i -E 's|github.com/go-asm/go/cmd/go/lockedfile/filelock|github.com/go-asm/go/cmd/go/lockedfile/internal/filelock|g'
	grep -rl 'github.com/go-asm/go/cmd/go/test/genflags' ${CURDIR}/** | grep -v -e Makefile | xargs sed -i -E 's|github.com/go-asm/go/cmd/go/test/genflags|github.com/go-asm/go/cmd/go/test/internal/genflags|g'
	grep -rl '"github.com/go-asm/go/cmd/compile/github.com/go-asm/go/pgo/graph"' ${CURDIR}/** | grep -v -e Makefile | xargs sed -i -E 's|"github.com/go-asm/go/cmd/compile/github.com/go-asm/go/pgo/graph"|"github.com/go-asm/go/cmd/compile/pgo/internal/graph"|g'
	sed -i 's|../../github.com/go-asm/go/cmd/reflectdata/reflect.go|src/cmd/reflectdata/reflect.go|g' reflectlite/type.go

.PHONY: fmt
fmt:
	@gofmt -w -s $(shell find . -type f -iwholename '*.go' -not -iwholename '*.git*' -not -iwholename '*testdata*')
	@goimports -w -local=github.com/go-asm/go $(shell find . -type f -iwholename '*.go' -not -iwholename '*.git*' -not -iwholename '*testdata*')

.PHONY: tidy
tidy:
	@rm -f go.sum 
	go mod download 
	go mod tidy

.PHONY: commit
commit:
	git add .
	git commit --gpg-sign --signoff -m "all: sync to go${GO_VERSION}"
	@rm -rf ${HOME}/sdk/go${GO_VERSION}

.PHONY: check
check:
	@go${GO_VERSION} download || true
	go build -o /dev/null ./...
	if go vet ./... 2>&1 | grep -E -v -e '#.*' -e 'missing Go declaration' -e 'possible misuse of unsafe.Pointer'; then exit 1; fi

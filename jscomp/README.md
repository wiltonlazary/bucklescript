Hello! This is the main directory for BuckleScript. `jscomp` is just a name that mirrors OCaml's own `bytecomp` and `asmcomp` (bytecode compilation and native compilation logic respectively). For building it, please see [CONTRIBUTING.md](../CONTRIBUTING.md).

Extra info:

## Rebuilding the browser-based playground

For best results, you probably want to complete the full [Setup](../CONTRIBUTING.md#setup) before following the below guidelines.

### Get `js_of_ocaml` from the normal switch

```
opam switch 4.02.3
eval `opam config env`
opam install js_of_ocaml
which js_of_ocaml # symlink this into your $PATH, maybe /usr/local/bin or something
```

### Do everything else from the bucklescript switch

You need to have [bucklescript-playground](https://github.com/BuckleScript/bucklescript-playground) cloned next to the Bucklescript directory for the following to work.

```
opam switch 4.02.3+buckle-master
eval `opam config env`
opam install camlp4 ocp-ocamlres
(cd vendor/ocaml && ./configure -prefix `pwd` && make world.opt)
(cd jscomp && BS_RELEASE_BUILD=true BS_PLAYGROUND=../../bucklescript-playground node repl.js)
```

## Sub directories

### [stdlib](./stdlib)

A copy of standard library from OCaml distribution(4.02) for fast development,
so that we don't need bootstrap compiler, everytime we deliver a new feature.

- Files copied
  - sources
  - Makefile.shared Compflags .depend Makefile
- Patches
  Most in [Makefile.shared](./stdlib/Makefile.shared)


## [test](./test)

The directory containing unit-test files, some unit tests are copied from OCaml distribution(4.02)

## compiler sourcetree

    - ext (portable)
    - common (portable)
    - bsb 
    - depends (portable)
    - core 
    - bspp
    - outcome_printer
    - stubs  
    - super_errors  
    - syntax 
## tools (deprecatd code)    
## xwatcher (dev tools)
## runtime    
## build_tests    
## bin
## cmd_tests
## ounit
## ounit_tests
## others (belt/stdlib/node bindings)


# bspack

ocamlopt.opt -I +compiler-libs unix.cmxa ./stubs/ext_basic_hash_stubs.c stubs/bs_hash_stubs.cmx  ocamlcommon.cmxa ext.cmxa common.cmxa depends.cmxa core/bspack_main.cmx -o bspack.dev
#!/usr/bin/env node

var p = require('child_process')
var fs = require('fs')
var path = require('path')

process.env.BS_RELEASE_BUILD = 1
var config =
    {
        cwd: __dirname,
        encoding: 'utf8',
        stdio: [0, 1, 2],
        shell: true
    }
function e(cmd) {
    console.log(`>>>>>> running command: ${cmd}`)
    p.execSync(cmd, config)
    console.log(`<<<<<<`)
}

if (process.env.BS_PLAYGROUND == null) {
    console.error('please set env var BS_PLAYGROUND')
    process.exit(2)
}

var playground = process.env.BS_PLAYGROUND

function prepare() {
    e(`hash hash js_of_ocaml 2>/dev/null || { echo >&2 "js_of_ocaml not found on path. Please install version 2.8.4 (although not with the buckelscript switch) and put it on your path."; exit 1; }
`)

    e(`hash ocp-ocamlres 2>/dev/null || { echo >&2 "ocp-ocamlres not installed. Please install: opam install ocp-ocamlres"; exit 1; }`)

    e(`hash camlp4 2>/dev/null || { echo >&2 "camlp4 not installed. Please install: opam install camlp4"; exit 1; }`)

    require('../scripts/release').run()

    try {
      fs.unlinkSync(path.join(__dirname, 'bin', 'js_compiler.ml'))
    } catch (err) {
      console.log(err)
    }

    e(`make -j2 bin/jscmj.exe bin/js_compiler.ml`)
    // bin/jsgen.exe 
    // e(`./bin/jsgen.exe --`)
    e(`./bin/jscmj.exe`)

    e(`ocamlc.opt -w -30-40 -no-check-prims -I bin bin/js_compiler.mli bin/js_compiler.ml -o jsc.byte`)

    e(`cp ../lib/js/*.js ${playground}/stdlib`)

    // Build JSX v2 PPX with jsoo
    try {
      fs.unlinkSync(path.join(__dirname, 'bin', 'jsoo_reactjs_jsx_ppx_v2.ml'))
    } catch (err) {
      console.log(err)
    }

    e(`make bin/jsoo_reactjs_jsx_ppx_v2.ml`)

    e(`ocamlc.opt -w -30-40 -no-check-prims -o jsoo_reactjs_jsx_ppx_v2.byte -I +compiler-libs ocamlcommon.cma bin/jsoo_reactjs_jsx_ppx_v2.ml`)
    e(`js_of_ocaml --disable share --toplevel +weak.js +toplevel.js jsoo_reactjs_jsx_ppx_v2.byte -I bin -I ../vendor/ocaml/lib/ocaml/compiler-libs -o ${playground}/jsoo_reactjs_jsx_ppx_v2.js`)

}

// needs js_cmj_datasets, preload.js and amdjs to be update
prepare()





console.log(`playground : ${playground}`)

var includes = [`stdlib`, `runtime`, `others`].map(x => path.join(__dirname, x)).map(x => `-I ${x}`).join(` `)

var cmi_files =
    [
        // `lazy`,
        `js`, `js_unsafe`, `js_re`, `js_array`, `js_null`, `js_undefined`,
        `js_types`, `js_null_undefined`, `js_dict`, `js_exn`, `js_string`, `js_vector`,
        `js_date`,
        `js_console`,
        `js_global`, `js_math`, `js_obj`, `js_int`,
        `js_result`, `js_list`, `js_typed_array`,
        `js_promise`, `js_option`, `js_float`, `js_json`,
        `arrayLabels`, `bytesLabels`, `complex`, `gc`, `genlex`, `listLabels`,
        `moreLabels`, `queue`, `scanf`, `sort`,`stack`, `stdLabels`, `stream`,
        `stringLabels`,
        `dom`,
        `belt`,
        `belt_Id`,
        `belt_Array`,
        `belt_SortArray`,
        `belt_SortArrayInt`,
        `belt_SortArrayString`,
        `belt_MutableQueue`,
        `belt_MutableStack`,
        `belt_List`,
        `belt_Range`,
        `belt_Set`,
        `belt_SetInt`,
        `belt_SetString`,
        `belt_Map`,
        `belt_MapInt`,
        `belt_Option`,
        `belt_MapString`,
        `belt_MutableSet`,
        `belt_MutableSetInt`,
        `belt_MutableSetString`,
        `belt_MutableMap`,
        `belt_MutableMapInt`,
        `belt_MutableMapString`,
        `belt_HashSet`,
        `belt_HashSetInt`,
        `belt_HashSetString`,
        `belt_HashMap`,
        `belt_HashMapInt`,
        `belt_HashMapString`,
    ].map(x => `${x}.cmi:/static/cmis/${x}.cmi`).map(x => `--file ${x}`).join(` `)
e(`js_of_ocaml --disable share --toplevel +weak.js ./polyfill.js jsc.byte ${includes} ${cmi_files} -o ${playground}/exports.js`)








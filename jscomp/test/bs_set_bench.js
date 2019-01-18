'use strict';

var Belt_SetInt = require("../../lib/js/belt_SetInt.js");
var Caml_builtin_exceptions = require("../../lib/js/caml_builtin_exceptions.js");

function bench(param) {
  var data = Belt_SetInt.empty;
  console.time("test/bs_set_bench.ml 7");
  for(var i = 0; i <= 1000000; ++i){
    data = Belt_SetInt.add(data, i);
  }
  console.timeEnd("test/bs_set_bench.ml 7");
  console.time("test/bs_set_bench.ml 11");
  for(var i$1 = 0; i$1 <= 1000000; ++i$1){
    if (!Belt_SetInt.has(data, i$1)) {
      throw [
            Caml_builtin_exceptions.assert_failure,
            /* tuple */[
              "bs_set_bench.ml",
              12,
              4
            ]
          ];
    }
    
  }
  console.timeEnd("test/bs_set_bench.ml 11");
  console.time("test/bs_set_bench.ml 14");
  for(var i$2 = 0; i$2 <= 1000000; ++i$2){
    data = Belt_SetInt.remove(data, i$2);
  }
  console.timeEnd("test/bs_set_bench.ml 14");
  if (Belt_SetInt.size(data) === 0) {
    return 0;
  } else {
    throw [
          Caml_builtin_exceptions.assert_failure,
          /* tuple */[
            "bs_set_bench.ml",
            17,
            2
          ]
        ];
  }
}

console.time("test/bs_set_bench.ml 21");

bench(/* () */0);

console.timeEnd("test/bs_set_bench.ml 21");

var count = 1000000;

var N = 0;

exports.count = count;
exports.N = N;
exports.bench = bench;
/*  Not a pure module */

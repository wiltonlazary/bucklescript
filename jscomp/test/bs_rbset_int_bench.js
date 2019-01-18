'use strict';

var Rbset = require("./rbset.js");
var Caml_builtin_exceptions = require("../../lib/js/caml_builtin_exceptions.js");

function bench(param) {
  var data = /* Empty */0;
  console.time("test/bs_rbset_int_bench.ml 7");
  for(var i = 0; i <= 1000000; ++i){
    data = Rbset.add(i, data);
  }
  console.timeEnd("test/bs_rbset_int_bench.ml 7");
  console.time("test/bs_rbset_int_bench.ml 11");
  for(var i$1 = 0; i$1 <= 1000000; ++i$1){
    if (!Rbset.mem(i$1, data)) {
      throw [
            Caml_builtin_exceptions.assert_failure,
            /* tuple */[
              "bs_rbset_int_bench.ml",
              12,
              4
            ]
          ];
    }
    
  }
  console.timeEnd("test/bs_rbset_int_bench.ml 11");
  console.time("test/bs_rbset_int_bench.ml 14");
  for(var i$2 = 0; i$2 <= 1000000; ++i$2){
    data = Rbset.remove(i$2, data);
  }
  console.timeEnd("test/bs_rbset_int_bench.ml 14");
  if (Rbset.cardinal(data) === 0) {
    return 0;
  } else {
    throw [
          Caml_builtin_exceptions.assert_failure,
          /* tuple */[
            "bs_rbset_int_bench.ml",
            17,
            2
          ]
        ];
  }
}

console.time("test/bs_rbset_int_bench.ml 21");

bench(/* () */0);

console.timeEnd("test/bs_rbset_int_bench.ml 21");

var count = 1000000;

var V = 0;

exports.count = count;
exports.V = V;
exports.bench = bench;
/*  Not a pure module */

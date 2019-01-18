'use strict';

var Mt = require("./mt.js");
var Block = require("../../lib/js/block.js");

function f(param) {
  var v = /* record */[/* contents */0];
  var acc = /* record */[/* contents */0];
  var n = 10;
  while(true) {
    if (v[0] > n) {
      return acc[0];
    } else {
      acc[0] = acc[0] + v[0] | 0;
      v[0] = v[0] + 1 | 0;
      continue ;
    }
  };
}

var suites_000 = /* tuple */[
  "sum",
  (function (param) {
      return /* Eq */Block.__(0, [
                55,
                f(/* () */0)
              ]);
    })
];

var suites = /* :: */[
  suites_000,
  /* [] */0
];

Mt.from_pair_suites("Loop_regression_test", suites);

exports.f = f;
exports.suites = suites;
/*  Not a pure module */

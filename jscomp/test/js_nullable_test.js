'use strict';

var Mt = require("./mt.js");
var Block = require("../../lib/js/block.js");

var suites = /* record */[/* contents : [] */0];

var test_id = /* record */[/* contents */0];

function eq(loc, x, y) {
  test_id[0] = test_id[0] + 1 | 0;
  suites[0] = /* :: */[
    /* tuple */[
      loc + (" id " + String(test_id[0])),
      (function (param) {
          return /* Eq */Block.__(0, [
                    x,
                    y
                  ]);
        })
    ],
    suites[0]
  ];
  return /* () */0;
}

function test(dom) {
  var elem = dom.getElementById("haha");
  if (elem == null) {
    return 1;
  } else {
    console.log(elem);
    return 2;
  }
}

function f(x, y) {
  console.log("no inline");
  return x + y | 0;
}

eq("File \"js_nullable_test.ml\", line 26, characters 7-14", false, false);

eq("File \"js_nullable_test.ml\", line 28, characters 7-14", (f(1, 2) == null), false);

eq("File \"js_nullable_test.ml\", line 30, characters 6-13", (null == null), true);

eq("File \"js_nullable_test.ml\", line 34, characters 3-10", false, false);

Mt.from_pair_suites("Js_nullable_test", suites[0]);

exports.suites = suites;
exports.test_id = test_id;
exports.eq = eq;
exports.test = test;
exports.f = f;
/*  Not a pure module */

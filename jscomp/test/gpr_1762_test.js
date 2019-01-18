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

var v = /* record */[/* contents */3];

function update(param) {
  v[0] = v[0] + 1 | 0;
  return true;
}

v[0] = v[0] + 1 | 0;

eq("File \"gpr_1762_test.ml\", line 22, characters 6-13", v[0], 4);

Mt.from_pair_suites("Gpr_1762_test", suites[0]);

exports.suites = suites;
exports.test_id = test_id;
exports.eq = eq;
exports.v = v;
exports.update = update;
/*  Not a pure module */

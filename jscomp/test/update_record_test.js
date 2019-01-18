'use strict';

var Mt = require("./mt.js");
var Block = require("../../lib/js/block.js");
var Caml_obj = require("../../lib/js/caml_obj.js");

var suites = /* record */[/* contents : [] */0];

var test_id = /* record */[/* contents */0];

function eq(loc, x, y) {
  console.log(/* tuple */[
        x,
        y
      ]);
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

function f(x) {
  var y = Caml_obj.caml_obj_dup(x);
  return /* record */[
          /* a0 */1,
          /* a1 */y[/* a1 */1],
          /* a2 */y[/* a2 */2],
          /* a3 */y[/* a3 */3],
          /* a4 */y[/* a4 */4],
          /* a5 */y[/* a5 */5]
        ];
}

eq("File \"update_record_test.ml\", line 30, characters 5-12", 1, f(/* record */[
            /* a0 */0,
            /* a1 */0,
            /* a2 */0,
            /* a3 */0,
            /* a4 */0,
            /* a5 */0
          ])[/* a0 */0]);

Mt.from_pair_suites("Update_record_test", suites[0]);

exports.suites = suites;
exports.test_id = test_id;
exports.eq = eq;
exports.f = f;
/*  Not a pure module */

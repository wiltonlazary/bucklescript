'use strict';

var Mt = require("./mt.js");
var Block = require("../../lib/js/block.js");
var Pervasives = require("../../lib/js/pervasives.js");

var suites_000 = /* tuple */[
  "string_of_float_1",
  (function (param) {
      return /* Eq */Block.__(0, [
                "10.",
                Pervasives.string_of_float(10)
              ]);
    })
];

var suites_001 = /* :: */[
  /* tuple */[
    "string_of_int",
    (function (param) {
        return /* Eq */Block.__(0, [
                  "10",
                  String(10)
                ]);
      })
  ],
  /* :: */[
    /* tuple */[
      "valid_float_lexem",
      (function (param) {
          return /* Eq */Block.__(0, [
                    "10.",
                    Pervasives.valid_float_lexem("10")
                  ]);
        })
    ],
    /* [] */0
  ]
];

var suites = /* :: */[
  suites_000,
  suites_001
];

Mt.from_pair_suites("Of_string_test", suites);

exports.suites = suites;
/*  Not a pure module */

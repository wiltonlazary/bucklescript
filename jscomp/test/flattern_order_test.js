'use strict';

var List = require("../../lib/js/list.js");
var Caml_obj = require("../../lib/js/caml_obj.js");

var ys = [];

Caml_obj.caml_update_dummy(ys, /* :: */[
      1,
      ys
    ]);

function _zs(param) {
  return /* tuple */[
          List.hd(ys),
          List.hd(xs[0])
        ];
}

var xs_000 = /* :: */[
  2,
  /* :: */[
    List.hd(ys),
    /* [] */0
  ]
];

var xs = /* tuple */[
  xs_000,
  _zs
];

function even(_n) {
  while(true) {
    var n = _n;
    if (n === 0) {
      return true;
    } else {
      _n = n - 1 | 0;
      continue ;
    }
  };
}

function even2(n) {
  if (n === 0) {
    return true;
  } else {
    var n$1 = n - 1 | 0;
    if (n$1 === 1) {
      return true;
    } else {
      return even2(n$1 - 1 | 0);
    }
  }
}

var v = /* record */[/* contents */0];

function obj_000(param) {
  return v[0];
}

function obj_001(i) {
  v[0] = i;
  return /* () */0;
}

var obj = /* record */[
  obj_000,
  obj_001
];

exports.xs = xs;
exports.even = even;
exports.even2 = even2;
exports.v = v;
exports.obj = obj;
/* xs Not a pure module */

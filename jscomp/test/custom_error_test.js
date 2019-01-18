'use strict';

var Js_exn = require("../../lib/js/js_exn.js");
var Caml_option = require("../../lib/js/caml_option.js");
var Caml_js_exceptions = require("../../lib/js/caml_js_exceptions.js");

function test_js_error(param) {
  var exit = 0;
  var e;
  try {
    e = JSON.parse(" {\"x\" : }");
    exit = 1;
  }
  catch (raw_exn){
    var exn = Caml_js_exceptions.internalToOCamlException(raw_exn);
    if (exn[0] === Js_exn.$$Error) {
      console.log(exn[1].stack);
      return undefined;
    } else {
      throw exn;
    }
  }
  if (exit === 1) {
    return Caml_option.some(e);
  }
  
}

function test_js_error2(param) {
  try {
    return JSON.parse(" {\"x\" : }");
  }
  catch (raw_e){
    var e = Caml_js_exceptions.internalToOCamlException(raw_e);
    if (e[0] === Js_exn.$$Error) {
      console.log(e[1].stack);
      throw e;
    } else {
      throw e;
    }
  }
}

function example1(param) {
  var exit = 0;
  var v;
  try {
    v = JSON.parse(" {\"x\"  }");
    exit = 1;
  }
  catch (raw_exn){
    var exn = Caml_js_exceptions.internalToOCamlException(raw_exn);
    if (exn[0] === Js_exn.$$Error) {
      console.log(exn[1].stack);
      return undefined;
    } else {
      throw exn;
    }
  }
  if (exit === 1) {
    return Caml_option.some(v);
  }
  
}

function example2(param) {
  try {
    return Caml_option.some(JSON.parse(" {\"x\"}"));
  }
  catch (raw_exn){
    var exn = Caml_js_exceptions.internalToOCamlException(raw_exn);
    if (exn[0] === Js_exn.$$Error) {
      return undefined;
    } else {
      throw exn;
    }
  }
}

exports.test_js_error = test_js_error;
exports.test_js_error2 = test_js_error2;
exports.example1 = example1;
exports.example2 = example2;
/* No side effect */

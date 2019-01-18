(* Copyright (C) 2015-2016 Bloomberg Finance L.P.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * In addition to the permissions granted to you by the LGPL, you may combine
 * or link a "work that uses the Library" with a publicly distributed version
 * of this file to produce a combined library or application, then distribute
 * that combined work under the terms of your choosing, with no requirement
 * to comply with the obligations normally placed on you by section 4 of the
 * LGPL version 3 (or the corresponding section of a later version of the LGPL
 * should you choose to use a later version).
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. *)


let setup_env () =
#if undefined BS_RELEASE_BUILD then
    (match Ext_sys.getenv_opt "BS_DEBUG_FILE" with 
     | None -> 
       Js_config.set_debug_file "caml_obj.ml"
     | Some s -> 
       Js_config.set_debug_file s 
    );
    (if Ext_sys.getenv_opt "BS_DEBUG_CHROME" <> None then 
      Js_config.debug := true);
#end
  Lexer.replace_directive_bool "BS" true;
  Lexer.replace_directive_string "BS_VERSION"  Bs_version.version
#if false then
  ; Switch.cut := 100 (* tweakable but not very useful *)
#end  

let standard_library =
#if undefined BS_RELEASE_BUILD then
  Filename.concat (Filename.dirname Sys.executable_name)  "ocaml"
#else
  Config.standard_library
#end

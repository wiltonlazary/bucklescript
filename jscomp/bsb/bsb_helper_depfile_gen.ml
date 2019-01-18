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



let dep_lit = " :"

let write_buf name buf  =     
  let oc = open_out_bin name in 
  Buffer.output_buffer oc buf ;
  close_out oc 

(* should be good for small file *)
let load_file name (buf : Buffer.t): unit  = 
  let len = Buffer.length buf in 
  let ic = open_in_bin name in 
  let n = in_channel_length ic in   
  if n <> len then begin close_in ic ; write_buf name buf  end 
  else
    let holder = really_input_string ic  n in 
    close_in ic ; 
    if holder <> Buffer.contents buf then 
      write_buf name buf 
;;
let write_file name  (buf : Buffer.t) = 
  if Sys.file_exists name then 
    load_file name buf 
  else 
    write_buf name buf 
    
(* Make suer it is the same as {!Binary_ast.magic_sep_char}*)
let magic_sep_char = '\n'

let deps_of_channel (ic : in_channel) : string array = 
  let size = input_binary_int ic in 
  let s = really_input_string ic size in 
  let first_tab  = String.index s magic_sep_char in 
  let return_arr = Array.make (int_of_string (String.sub s 0 first_tab)) "" in 
  let rec aux s ith (offset : int) : unit = 
    if offset < size then
      let next_tab = String.index_from s offset magic_sep_char  in 
      return_arr.(ith) <- String.sub s offset (next_tab - offset) ; 
      aux s (ith + 1) (next_tab + 1) 
  in 
  aux s 0 (first_tab + 1) ; 

  return_arr 

(** Please refer to {!Binary_ast} for encoding format, we move it here 
    mostly for cutting the dependency so that [bsb_helper.exe] does
    not depend on compler-libs
*)
let read_deps (fn : string) : string array = 
  let ic = open_in_bin fn in 
  let v = deps_of_channel ic in 
  close_in ic;
  v


type kind = Js | Bytecode | Native

let output_file (oc : Buffer.t) source namespace = 
  match namespace with 
  | None -> Buffer.add_string oc source 
  | Some ns ->
    Buffer.add_string oc (Ext_namespace.make ~ns source)

(** for bucklescript artifacts 
    [lhs_suffix] is [.cmj]
    [rhs_suffix] 
    is [.cmj] if it has [ml] (in this case does not care about mli or not)
    is [.cmi] if it has [mli]
*)
let oc_cmi buf namespace source = 
  Buffer.add_char buf '\n';  
  output_file buf source namespace;
  Buffer.add_string buf Literals.suffix_cmi 


let handle_module_info 
    (module_info : Bsb_db.module_info)
    input_file 
    namespace rhs_suffix buf = 
  let source = module_info.name_sans_extension in 
  if source <> input_file then 
    begin 
      if module_info.ml_info <> Ml_empty then 
        begin
          Buffer.add_char buf '\n';  
          output_file buf source namespace;
          Buffer.add_string buf rhs_suffix
        end;
      (* #3260 cmj changes does not imply cmi change anymore *)
      oc_cmi buf namespace source
    end
let oc_impl 
    (dependent_module_set : string array)
    (input_file : string)
    (lhs_suffix : string)
    (rhs_suffix : string)
    (index : Bsb_dir_index.t)
    (data : Bsb_db_io.t)
    (namespace : string option)
    (buf : Buffer.t)
  = 
  output_file buf input_file namespace ; 
  Buffer.add_string buf lhs_suffix; 
  Buffer.add_string buf dep_lit ; 
  for i = 0 to Array.length dependent_module_set - 1 do
    let k = Array.unsafe_get dependent_module_set i in 
    match Bsb_db_io.find_opt  data 0 k with
    | Some module_info -> 
      handle_module_info module_info input_file namespace rhs_suffix buf
    | None  -> 
      if not (Bsb_dir_index.is_lib_dir index) then      
        Ext_option.iter (Bsb_db_io.find_opt data ((index  :> int)) k)
          (fun module_info -> 
             handle_module_info module_info input_file namespace rhs_suffix buf)
  done    


(** Note since dependent file is [mli], it only depends on 
    [.cmi] file
*)
let oc_intf
    (dependent_module_set : string array)
    input_file 
    (index : Bsb_dir_index.t)
    (data : Bsb_db_io.t)
    (namespace : string option)
    (buf : Buffer.t) =   
  output_file buf input_file namespace ; 
  Buffer.add_string buf Literals.suffix_cmi ; 
  Buffer.add_string buf dep_lit;
  for i = 0 to Array.length dependent_module_set - 1 do               
    let k = Array.unsafe_get dependent_module_set i in 
    match Bsb_db_io.find_opt data 0 k with 
    | Some module_info -> 
      let source = module_info.name_sans_extension in 
      if source <> input_file then oc_cmi buf namespace source             
    | None -> 
      if not (Bsb_dir_index.is_lib_dir index)  then 
        Ext_option.iter (Bsb_db_io.find_opt data ((index :> int)) k)
          ( fun module_info -> 
              let source = module_info.name_sans_extension in 
              if source <> input_file then  oc_cmi buf namespace source)
  done  


(* OPT: Don't touch the .d file if nothing changed *)
let emit_dep_file
    compilation_kind
    (fn : string)
    (index : Bsb_dir_index.t) 
    (namespace : string option) : unit = 
  let data  =
    Bsb_db_io.read_build_cache 
      ~dir:Filename.current_dir_name
  in 
  let set = read_deps fn in 
  match Ext_string.ends_with_then_chop fn Literals.suffix_mlast with 
  | Some  input_file -> 
#if BS_NATIVE then   
    let lhs_suffix, rhs_suffix =
      match compilation_kind with
      | Js       -> Literals.suffix_cmj, Literals.suffix_cmj
      | Bytecode -> Literals.suffix_cmo, Literals.suffix_cmi
      | Native   -> Literals.suffix_cmx, Literals.suffix_cmx 
    in    
#else     
   let lhs_suffix = Literals.suffix_cmj in   
   let rhs_suffix = Literals.suffix_cmj in 
#end
   let buf = Buffer.create 64 in 
   oc_impl 
     set 
     input_file 
     lhs_suffix 
     rhs_suffix  
     index 
     data
     namespace
     buf ;
    let filename = (input_file ^ Literals.suffix_mlastd ) in 
    write_file filename buf 
    
  | None -> 
    begin match Ext_string.ends_with_then_chop fn Literals.suffix_mliast with 
      | Some input_file -> 
        let filename = (input_file ^ Literals.suffix_mliastd) in 
        let buf = Buffer.create 64 in 
        oc_intf 
          set 
          input_file 
          index 
          data 
          namespace 
          buf; 
        write_file filename buf 
      | None -> 
        raise (Arg.Bad ("don't know what to do with  " ^ fn))
    end

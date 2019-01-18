(* Copyright (C) 2017 Authors of BuckleScript
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


let map_row_fields_into_ints ptyp_loc
    (row_fields : Parsetree.row_field list) 
  = 
  let _, acc
    = 
    (List.fold_left 
       (fun (i,acc) rtag -> 
          match rtag with 
          | Parsetree.Rtag (label, attrs, true,  [])
            -> 
            begin match Ast_attributes.iter_process_bs_int_as attrs with 
              | Some i -> 
                i + 1, 
                ((Ast_compatible.hash_label label , i):: acc ) 
              | None -> 
                i + 1 , 
                ((Ast_compatible.hash_label label , i):: acc )
            end
          | _ -> 
            Bs_syntaxerr.err ptyp_loc Invalid_bs_int_type
       ) (0, []) row_fields) in 
  List.rev acc

(** Note this is okay with enums, for variants,
    the underlying representation may change due to       
    unbox
*)
let map_constructor_declarations_into_ints 
    (row_fields : Parsetree.constructor_declaration list)
  = 
  let mark = ref `nothing in 
  let _, acc
    = 
    (List.fold_left 
       (fun (i,acc) (rtag : Parsetree.constructor_declaration) -> 

          let attrs = rtag.pcd_attributes in 
          begin match Ast_attributes.iter_process_bs_int_as attrs with 
            | Some j -> 
              if j <> i then 
                (
                  if i = 0 then mark := `offset j
                  else mark := `complex
                )
              ;
              (j + 1, 
               (j:: acc ) )
            | None -> 
              i + 1 , 
              ( i:: acc )
          end

       ) (0, []) row_fields) in 
  match !mark with 
  | `nothing -> `Offset 0
  | `offset j -> `Offset j 
  | `complex -> `New (List.rev acc)



(** It also check in-consistency of cases like 
    {[ [`a  | `c of int ] ]}       
*)  
let map_row_fields_into_strings ptyp_loc 
    (row_fields : Parsetree.row_field list) : External_arg_spec.attr = 
  let case, result = 
    Ext_list.fold_right row_fields (`Nothing, []) (fun tag (nullary, acc) -> 
        match nullary, tag with 
        | (`Nothing | `Null), 
          Rtag (label, attrs, true,  [])
          -> 
          begin match Ast_attributes.iter_process_bs_string_as attrs with 
            | Some name -> 
              `Null, ((Ast_compatible.hash_label label, name) :: acc )

            | None -> 
              `Null, ((Ast_compatible.hash_label label, Ast_compatible.label_of_name label) :: acc )
          end
        | (`Nothing | `NonNull), Rtag(label, attrs, false, ([ _ ])) 
          -> 
          begin match Ast_attributes.iter_process_bs_string_as attrs with 
            | Some name -> 
              `NonNull, ((Ast_compatible.hash_label label, name) :: acc)
            | None -> 
              `NonNull, ((Ast_compatible.hash_label label, Ast_compatible.label_of_name label) :: acc)
          end
        | _ -> Bs_syntaxerr.err ptyp_loc Invalid_bs_string_type

      )  in 
  match case with 
  | `Nothing -> Bs_syntaxerr.err ptyp_loc Invalid_bs_string_type
  | `Null -> External_arg_spec.NullString result 
  | `NonNull -> NonNullString result


let is_enum row_fields = 
  List.for_all (fun (x : Parsetree.row_field) -> 
      match x with 
      | Rtag(_label,_attrs,true, []) -> true 
      | _ -> false
    ) row_fields


let is_enum_polyvar (ty : Parsetree.type_declaration) =      
  match ty.ptype_manifest with 
  | Some {ptyp_desc = Ptyp_variant(row_fields,Closed,None)}
    when is_enum row_fields ->
    Some row_fields 
  | _ -> None 

let is_enum_constructors 
    (constructors : Parsetree.constructor_declaration list) =   
  List.for_all 
    (fun (x : Parsetree.constructor_declaration) ->
       match x with 
       | {pcd_args = 
#if OCAML_VERSION =~ ">4.03.0" then 
  Pcstr_tuple [] (* Note the enum is encoded using [Pcstr_tuple []]*)
#else  
        []
#end        
        } -> true 
       | _ -> false 
    )
    constructors
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










(* Assume that functions already calculated closure correctly 
   Maybe in the future, we should add a dirty flag, to mark the calcuated 
   closure is correct or not

   Note such shaking is done in the toplevel, so that it requires us to 
   flatten the statement first 
*)
let free_variables used_idents defined_idents = 
  object (self)
    inherit Js_fold.fold as super
    val defined_idents = defined_idents
    val used_idents = used_idents 
    method! variable_declaration st = 
      match st with 
      | { ident; value = None}
        -> 
        {< defined_idents = Ident_set.add ident defined_idents >}
      | { ident; value = Some v}
        -> 
        {< defined_idents = Ident_set.add ident defined_idents >} # expression v
    method! ident id = 
      if Ident_set.mem id defined_idents then self
      else {<used_idents = Ident_set.add id used_idents >}
    method! expression exp = 

      match exp.expression_desc with
      | Fun(_, _,_, env)
        (** a optimization to avoid walking into funciton again
            if it's already comuted
        *)
        ->
        {< used_idents = 
             Ident_set.union (Js_fun_env.get_unbounded env) used_idents  >}

      | _
        ->
        super#expression exp

    method get_depenencies = 
      Ident_set.diff used_idents defined_idents
    method get_used_idents = used_idents
    method get_defined_idents = defined_idents 
  end 

let free_variables_of_statement used_idents defined_idents st = 
  ((free_variables used_idents defined_idents)#statement st) # get_depenencies

let free_variables_of_expression used_idents defined_idents st = 
  ((free_variables used_idents defined_idents)#expression st) # get_depenencies

let rec no_side_effect_expression_desc (x : J.expression_desc)  = 
  match x with 
  | Raw_js_function _
  | Undefined
  | Null
  | Bool _ 
  | Var _ 
  | Unicode _ -> true 
  | Fun _ -> true
  | Number _ -> true (* Can be refined later *)
  | String_index (a,b)
  | Array_index (a,b) -> no_side_effect a && no_side_effect b 
  | Is_null_or_undefined b -> no_side_effect b 
  | Str (b,_) -> b    
  | Array (xs,_mutable_flag)  
  | Caml_block (xs, _mutable_flag, _, _)
    ->
    (** create [immutable] block,
        does not really mean that this opreation itself is [pure].

        the block is mutable does not mean this operation is non-pure
    *)
    Ext_list.for_all xs no_side_effect 
  | Optional_block (x,_) -> no_side_effect x   
  | Object kvs -> 
    Ext_list.for_all_snd  kvs no_side_effect
  | String_append (a,b)
  | Seq (a,b) -> no_side_effect a && no_side_effect b 
  | Length (e, _)
  | Char_of_int e 
  | Char_to_int e 
  | Caml_block_tag e 
  | Typeof e
    -> no_side_effect e 
  | Bin (op, a, b) -> 
    op <> Eq && no_side_effect a && no_side_effect b     
  | Js_not _
  | Cond _ 
  | FlatCall _ 
  | Call _ 
  | Static_index _ 
  | New _ 
  | Raw_js_code _ 
  (* | Caml_block_set_tag _  *)
  (* actually true? *)
    -> false 
and no_side_effect (x : J.expression)  = 
  no_side_effect_expression_desc x.expression_desc

let no_side_effect_expression (x : J.expression) = no_side_effect x 

let no_side_effect init = 
  object (self)
    inherit Js_fold.fold as super
    val no_side_effect = init
    method get_no_side_effect = no_side_effect

    method! statement s = 
      if not no_side_effect then self else 
        match s.statement_desc with 
        | Throw _ 
        | Debugger 
        | Break 
        | Variable _ 
        | Continue _ ->  
          {< no_side_effect = false>}
        | Exp e -> self#expression e 
        | Int_switch _ | String_switch _ | ForRange _ 
        | If _ | While _   | Block _ | Return _ | Try _  -> super#statement s 
    method! list f x = 
      if not self#get_no_side_effect then self else super#list f x 
    method! expression s = 
      if not no_side_effect then self
      else  {< no_side_effect = no_side_effect_expression s >}

    (** only expression would cause side effec *)
  end
let no_side_effect_statement st = ((no_side_effect true)#statement st)#get_no_side_effect

(* TODO: generate [fold2] 
   This make sense, for example:
   {[
     let string_of_formatting_gen : type a b c d e f .
       (a, b, c, d, e, f) formatting_gen -> string =
       fun formatting_gen -> match formatting_gen with
         | Open_tag (Format (_, str)) -> str
         | Open_box (Format (_, str)) -> str

   ]}
*)
let rec eq_expression 
    ({expression_desc = x0}  : J.expression) 
    ({expression_desc = y0}  : J.expression) = 
  begin match x0  with 
    | Null -> y0 = Null
    | Undefined -> y0 = Undefined
    | Number (Int i) -> 
      begin match y0 with  
        | Number (Int j)   -> i = j 
        | _ -> false 
      end
    | Number (Float i) -> 
      begin match y0 with 
        | Number (Float j) ->
          false (* conservative *)
        | _ -> false 
      end    
    | String_index (a0,a1) -> 
      begin match y0 with 
        | String_index(b0,b1) -> 
          eq_expression a0 b0 && eq_expression a1 b1
        | _ -> false 
      end
    | Array_index (a0,a1) -> 
      begin match y0 with 
        | Array_index(b0,b1) -> 
          eq_expression a0 b0 && eq_expression a1 b1
        | _ -> false 
      end
    | Call (a0,args00,_) -> 
      begin match y0 with 
        | Call(b0,args10,_) ->
          eq_expression a0 b0 &&  eq_expression_list args00 args10
        | _ -> false 
      end 
    | Var (Id i) -> 
      begin match y0 with 
        | Var (Id j) ->
          Ident.same i j
        | _ -> false
      end
    | Bin (op0, a0,b0) -> 
      begin match y0 with 
        | Bin(op1,a1,b1) -> 
          op0 = op1 && eq_expression a0 a1 && eq_expression b0 b1
        | _ -> false 
      end 
    | Str(a0,b0) -> 
      begin match y0 with 
        | Str(a1,b1) -> a0 = a1  && b0 = b1
        | _ -> false 
      end     
    | Var (Qualified (id0,k0,opts0)) -> 
      begin match y0 with 
        | Var (Qualified (id1,k1,opts1)) ->
          Ident.same id0 id1 &&
          k0 = k1 &&
          opts0 = opts1
        | _ -> false
      end
    | Static_index (e0,p0) -> 
      begin match y0 with 
        | Static_index(e1,p1) -> 
          p0 = p1 && eq_expression e0 e1
        |  _ -> false 
      end
    | Seq (a0,b0) -> 
      begin match y0 with       
        | Seq(a1,b1) -> 
          eq_expression a0 a1 && eq_expression b0 b1
        | _ -> false 
      end
    | Bool a0 -> 
      begin match y0 with 
        | Bool b0 -> a0 = b0
        | _ -> false 
      end
    | Optional_block (a0,b0) -> 
      begin match y0 with   
      | Optional_block (a1,b1) -> b0 = b1 && eq_expression a0 a1
      | _ -> false 
      end 
    | Caml_block (ls0,flag0,tag0,_) ->    
      begin match y0 with 
      | Caml_block(ls1,flag1,tag1,_) -> 
        eq_expression_list ls0 ls1 &&
        flag0 = flag1 &&
        eq_expression tag0 tag1 
      | _ -> false 
      end 
    | Length _ 
    | Char_of_int _
    | Char_to_int _ 
    | Is_null_or_undefined _ 
    | String_append _ 
    | Typeof _ 
    | Js_not _ 
    | Cond _ 
    | FlatCall  _
  
    | New _ 
    | Fun _ 
    | Unicode _ 
    | Raw_js_code _
    | Raw_js_function _
    | Array _ 
    | Caml_block_tag _ 
    
    | Object _ 
    | Number (Uint _ | Nint _)

      ->  false 
  end
and eq_expression_list xs ys =
  Ext_list.for_all2_no_exn xs ys eq_expression
and eq_block (xs : J.block) (ys : J.block) =
  Ext_list.for_all2_no_exn xs ys eq_statement
and eq_statement 
    ({statement_desc = x0} : J.statement)
    ({statement_desc = y0} : J.statement) = 
  match x0  with 
  | Exp a -> 
    begin match y0 with 
      | Exp b -> eq_expression a b 
      | _ -> false
    end
  | Return { return_value = a ; _} -> 
    begin match y0 with 
      | Return { return_value = b; _} ->
        eq_expression a b
      | _ -> false 
    end
  | Debugger -> y0 = Debugger  
  | Break -> y0 = Break 
  | Block xs0 -> 
    begin match y0 with 
    | Block ys0 -> 
      eq_block xs0 ys0
    | _ -> false 
  end
  | Variable _ 
  | If _ 
  | While _ 
  | ForRange _ 
  | Continue _ 
  
  | Int_switch _ 
  | String_switch _ 
  | Throw _ 
  | Try _ 
    -> 
    false 

let rev_flatten_seq (x : J.expression) = 
  let rec aux acc (x : J.expression) : J.block = 
    match x.expression_desc with
    | Seq(a,b) -> aux (aux acc a) b 
    | _ -> { statement_desc = Exp x; comment = None} :: acc in
  aux [] x 

(* TODO: optimization, 
    counter the number to know if needed do a loop gain instead of doing a diff 
*)

let rev_toplevel_flatten block = 
  let rec aux  acc (xs : J.block) : J.block  = 
    match xs with 
    | [] -> acc
    | {statement_desc =
         Variable (
           {ident_info = {used_stats = Dead_pure } ; _} 
         | {ident_info = {used_stats = Dead_non_pure}; value = None })
      } :: xs -> aux acc xs 
    | {statement_desc = Block b; _ } ::xs -> aux (aux acc b ) xs 

    | x :: xs -> aux (x :: acc) xs  in
  aux [] block

let rec is_constant (x : J.expression)  = 
  match x.expression_desc with 
  | Array_index (a,b) -> is_constant a && is_constant b 
  | Str (b,_) -> b
  | Number _ -> true (* Can be refined later *)
  | Array (xs,_mutable_flag)  -> Ext_list.for_all xs  is_constant 
  | Caml_block(xs, Immutable, tag, _) 
    -> Ext_list.for_all xs is_constant && is_constant tag 
  | Bin (op, a, b) -> 
    is_constant a && is_constant b     
  | _ -> false 


let rec is_okay_to_duplicate (e : J.expression) = 
  match e.expression_desc with  
  | Var _ 
  | Bool _ 
  | Str _ 
  | Number _ -> true
  | Static_index (e, _s) -> is_okay_to_duplicate e 
  | _ -> false 

let suites :  Mt.pair_suites ref  = ref []
let test_id = ref 0
let eq loc x y = Mt.eq_suites ~suites ~test_id loc x y
let b loc v  = Mt.bool_suites ~suites ~test_id loc v

module Icmp =
  (val Belt.Id.comparable
      ~cmp:(fun (x : int) y ->  compare x y
      )
  )
module M = Belt.MutableMap
module N = Belt.Set

module A = Belt.Array
module I = Array_data_util
let f x = M.fromArray ~id:(module Icmp) x
let ff x = N.fromArray ~id:(module Icmp) x


let randomRange i j =
  A.map (I.randomRange i j) (fun x -> (x,x))


  let () =
    let a0 = f (randomRange 0 10) in
    M.set a0 3 33;
    eq __LOC__ (M.getExn a0 3) 33 ;
    M.removeMany a0 [|7;8;0;1;3;2;4;922;4;5;6;|];
    eq __LOC__ (M.keysToArray a0) [|9;10|];
    M.removeMany a0 (I.randomRange 0 100);
    b __LOC__ (M.isEmpty a0)



;; Mt.from_pair_suites __MODULE__ !suites

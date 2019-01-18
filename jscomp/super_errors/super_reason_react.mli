val component_spec_weak_type_variables: Types.type_expr -> bool * bool * bool
(** Used by super_typemod when we detect the message "... contains type variables that cannot be generalized" *)

val component_spec_weak_type_variables_in_module_type: Types.module_type -> (bool * bool * bool) list
(** Used by super_typemod when we detect the message "... contains type variables that cannot be generalized" *)

val state_escape_scope: (Types.type_expr * Types.type_expr) list -> bool
(** Used by super_typecore when we detect the message "The type constructor state would escape its scope" *)

val trace_both_component_spec: (Types.type_expr * Types.type_expr) list -> bool
(** Used by super_typecore when we detect the message "The type constructor state would escape its scope" *)

val is_component_spec_wanted_react_element: (Types.type_expr * Types.type_expr) list -> bool
(** Used by super_typecore when we detect the message "This has type componentSpec but expected reactElement" *)

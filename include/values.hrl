% @type value() = runtime_value() | abstract_value() | compiletime_value().

% @type runtime_value() = object:struct_loc() | object:array_loc() | object:lock_loc() | heap:activation_loc() | nil_() | num() | sym() | block_ref().
% those values are available during runtime, a.k.a. immediates.

% @type abstract_value() = any_() | some() | option().
% Tose values are generated during merges in the analysis.

% @type compiletime_value() = reg() | slot() | this() | struct() | array() | lock() | now() | nil_() | num() | sym() | block_ref() | act_block() | act_struct().
% those values are (also) generated by the parser

% @type slot_name_value() = reg() | sym() | num().
% A value that can be used as a slot name

% @type creating_value() = sym() | num() | block_ref() | new_struct() | new_array() | new_lock() | instructions:activate() | instructions:intrinsic().
% a value that creates a new entity for the analysis such as constants and new statements
% all those values have a block-local id (called nth) to distinguish them syntactically

% @type new_statement() = new_struct() | new_array() | new_lock().

% *****************************
% runtime values
% *****************************

% see heap.hrl

% *****************************
% abstract values
% *****************************

% @type value_type() = sym | num | block | loc | act.

% @type any_().
% a placeholder for any value with any value type.
-record (any, {}).

% @type some(Type)
% 	Type = value_type().
% A placeholder for some value of a known type.
-record (some, {type}).

% @type one_of(Type, ValueSet)
%	Type = value_type()
%	ValueSet = set(value()).
% A set of concrete values of the given type.
-record (one_of, {type, value_set}).

%a transformed value is a primitive immutable value (number etc) that is transformed by an operation
%such as inc or plus 32 or something
%type is for example num or sym
%it contains the Nth and the Activation Node where that transformation happened
%the parent value is either another transformed value of the same type or a value
-record (transformed_value, {type, nth, node_id, parent_value, operation}).

% *****************************
% immediate values
% *****************************

% @type sym(Value)
% 	Name = atom().
% A symbol
% Example: <pre>'symname</pre>
-record (sym, {name}).

% @type num(Value)
%	Value = integer() | float().
% A nummeric value
% Example: <pre>42</pre>
-record (num, {value}).

% @type block_ref(Nth, Name)
% 	Nth = integer(),
%	Name = atom().
% A reference to another block;
-record (block_ref, {nth, name}).

% @type act_block(Activation)
%	Activation = now() | reg().
% the block of an activation as a value
% Example: <pre>now#block</pre>
-record (act_block, {activation}).

% @type act_struct(Activation)
%	Activation = now() | reg().
% the struct of an activation as a value
% Example: <pre>now#struct ; this is equivalent to 'this'</pre>
-record (act_struct, {activation}).

% @type nil_().
% Example: <pre>nil</pre>
-record (nil, {}).

% @type reg(Name)
%	Name = atom().
% a reference to the register with the given name.
% Example: <pre>%regname</pre>
-record (reg, {name}). %register name

% @type slot(Context, Slot)
%	Context = reg() | this()
% 	Slot = slot_name_value().
-record (slot, {context, slot}).

% @type this().
% Example: <pre>this</pre>
-record (this, {}).

% @type struct().
% creates a new struct
% Example: <pre>struct</pre>
-record (new_struct, {nth}).

% @type array().
% creates a new array
% Example: <pre>array</pre>
-record (new_array, {nth}).

% @type lock().
% creates a new lock
% Example: <pre>lock</pre>
-record (new_lock, {nth}).

% @type now().
% Example: <pre>now</pre>
-record (now, {}).

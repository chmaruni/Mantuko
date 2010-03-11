Nonterminals 
file
opt_macro_list macro
block body
instruction value 
register symbol number 
slot slot_or_reg
slot_value struct_value
value_list opt_value_list
register_list
activation_lhs activation_rhs
activation_value.

Terminals
tick comma equals
lparen rparen lcurl rcurl lsquare rsquare
ident num
this nil now
struct array lock
percent fork
act_block act_struct
colon
schedule.

Rootsymbol file.

%we use {main} as the id for the main block so that the atom main can be used as a macro name
% the first element in the returned block array will be the main block
file -> opt_macro_list block opt_macro_list	: 					
					Repository1 = loader:add_all_blocks('$1', loader:new()),
					Repository2 = loader:add_all_blocks('$3', Repository1),
					loader:add_block('$2'#block{id={main}}, Repository2).

opt_macro_list -> '$empty'		: [].
opt_macro_list -> macro opt_macro_list : ['$1'|'$2'].

macro -> ident colon block : '$3'#block{id=list_to_atom(unwrap('$1'))}. 

block -> lcurl body rcurl	: 
			{_,Start} = '$1',
			{_, End} = '$3',
			#block{filename=?FILENAME, start_line=Start, end_line=End, body='$2'}.
			
block -> lcurl rcurl	: 
			{_,Start} = '$1',
			{_, End} = '$2',
			#block{filename=?FILENAME, start_line=Start, end_line=End, body=[]}.
block -> colon ident : #block_ref{id=list_to_atom(unwrap('$2'))}.

body -> instruction					: ['$1'].
body -> instruction body	: case '$1' of
									none -> '$2';
									Else -> [Else|'$2']
								  end.

%%
%% INSTRUCTIONS
%%
instruction ->  register equals value	
					: #move{line_no=line_no('$2'), target='$1', value='$3'}.
instruction -> slot equals value	
					: #move{line_no=line_no('$2'), target='$1', value='$3'}.
% NOTE: it doesn't make sense to add a now -> %reg variant
% because: this only succeeds if there is an edge from now to %reg already 
% and then the edge would be redundant
instruction -> slot_or_reg schedule slot_or_reg	
					: #schedule{line_no=line_no('$2'), lhs='$1', rhs='$3'}.
instruction -> fork activation_lhs lparen activation_rhs rparen
					: #activate{line_no=line_no('$1'), reg=undefined, block='$2', struct='$4'}.
instruction -> register equals fork activation_lhs lparen activation_rhs rparen
					: #activate{line_no=line_no('$2'), reg='$1', block='$4', struct='$6'}.

%%
%% PRIMITIVES
%%
%% primitive forms: %foo v1, v2; r1 = %foo v2; r1, r2 = %foo v4
instruction -> ident lparen opt_value_list rparen
					: #intrinsic{line_no=line_no('$1'), name=list_to_atom(unwrap('$1')), out_registers=[], in_values='$3'}.
instruction -> register equals ident lparen opt_value_list rparen
					: #intrinsic{line_no=line_no('$2'), name=list_to_atom(unwrap('$3')), out_registers=['$1'], in_values='$5'}.
instruction -> register comma register_list equals ident lparen opt_value_list rparen
					: #intrinsic{line_no=line_no('$4'), name=list_to_atom(unwrap('$5')), out_registers=['$1'|'$3'], in_values='$7'}.

opt_value_list -> '$empty' : [].
opt_value_list -> value_list : '$1'.

value_list -> value : ['$1'].
value_list -> value comma value_list : ['$1'|'$3'].

register_list -> register : ['$1'].
register_list -> register comma register_list : ['$1'|'$3'].

%%
%% INDIRECT READS/WRITES
%%

%we don't allow a slot to be used as a slot value because that allows recursion and we don't want that
% in the assembly language (e.g., this[%reg[this['foo]]])
slot_value -> register : '$1'.
slot_value -> symbol : '$1'.
slot_value -> number : '$1'.

%same here, we don't want to have this['foo]['bar]['blubb] in the assembly even though it would work easily
struct_value -> register : '$1'.
struct_value -> this : #this{}.

%%
%% VALUES
%%
value -> slot : '$1'.
value -> register : '$1'.
value -> symbol : '$1'.
value -> number : '$1'.
value -> block : '$1'.
value -> this : #this{}.
value -> struct : #struct{}.
value -> array : #array{}.
value -> lock : #lock{}.
value -> nil : #nil{}.
value -> now : #now{}.
value -> activation_value act_block : #act_block{activation='$1'}.
value -> activation_value act_struct : #act_struct{activation='$1'}.

activation_value -> now : '$1'.
activation_value -> slot_or_reg : '$1'.

% registers in read-position can also be slots because that doesn't require any special handling by the interpreter
slot_or_reg -> register : '$1'.
slot_or_reg -> slot : '$1'.

slot -> struct_value lsquare slot_value rsquare : #slot{context='$1', slot='$3'}.
register -> percent ident : #reg{name=list_to_atom(unwrap('$2'))}.
symbol -> tick ident : #sym{name=list_to_atom(unwrap('$2'))}.
number -> num : #num{value=nummeric_value_from_string_token('$1')}.

%%
%% ACTIVATIONS
%%
activation_lhs -> slot_or_reg : '$1'.
activation_lhs -> block : '$1'.

activation_rhs -> slot_or_reg : '$1'.
activation_rhs -> struct : #struct{}.
activation_rhs -> this : #this{}.

Erlang code.

-include("include/instructions.hrl").
-include("include/values.hrl").
-export([parse_from_string/2]).

%*********************************
%helpers used in the grammar
%*********************************
unwrap({_,_,V}) -> V.

line_no({_,LineNo,_}) -> LineNo;
line_no({_,LineNo}) -> LineNo.

nummeric_value_from_string_token({_, _, V}) ->
	case erl_scan:string(V) of
		{ok, [{integer, _, Value}], _} ->
			Value;
		Some ->
			tracer:fatal(?MODULE, nummeric_value_from_string_token, "Illegal nummeric value: ~p", [Some])
	end.

%*********************************
%extended interface for the parser
%*********************************
-define(FILENAME, get(filename)).

% @spec parse_from_string(Filename::string(), Program::string())-> loader:code_repository() | {error, Reason}
% @end
% returns a list of blocks; the first block has id {main}
parse_from_string(Filename, String) ->
	put(filename, Filename),
	{ok,Tokens,_} = lexer:string(String),	
	parse(Tokens).
	
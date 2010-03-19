-module (struct).

-include("include/values.hrl").
-include("include/debug.hrl").

-export ([new/0]).
-export ([set/3, get/2]).

-record (struct, {slots}).

new() ->
	#struct{slots=dict:new()}.

set(#sym{}=Slot, #nil{}, Struct) ->	
	?f("setting struct slot ~w to nil", [Slot]),
	Struct#struct{slots=dict:erase(Slot, Struct#struct.slots)};
set(#sym{}=Slot, Value, Struct) ->
	?f("setting struct slot ~w to ~w", [Slot, Value]),
	Struct#struct{slots=dict:store(Slot, Value, Struct#struct.slots)}.
	
get(#sym{}=Slot, Struct) ->
	case dict:find(Slot, Struct#struct.slots) of
		{ok, Value} -> 
			?f("getting struct slot ~w => ~w", [Slot, Value]),
			Value;
		error -> 
			?f("getting struct slot ~w => nil", [Slot]),
			#nil{}
	end.
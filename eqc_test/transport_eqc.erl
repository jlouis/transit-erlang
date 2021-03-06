%% jsx_eqc provides a model of JSON in jsx style in order to test JSX for correctness
-module(transport_eqc).

-include_lib("eqc/include/eqc.hrl").
-compile(export_all).

json_integer() ->
    int().
    
json_float() ->
    real().

json_number() ->
    oneof([json_integer(), json_float()]).

json_string() ->
    eqc_lib:utf8_string().
    
json_mp_atom() ->
    elements([true, false, nil]).

json_atom() ->
    elements([true, false, null]).
    
json_map(G) ->
    ?LET(L, list({eqc_lib:utf8_string(), G}),
      maps:from_list(L)).

json_mp_map(G) -> list({eqc_lib:utf8_string(), G}).

json_term() ->
    ?SIZED(N, json_term(N)).
    
json_term(0) ->
    oneof([
      json_integer(),
      json_float(),
      json_number(),
      json_string(),
      json_atom()
    ]);
json_term(N) ->
    frequency([
      {1, json_term(0)},
      {N, ?LAZY(list(json_term(N div 4)))},
      {N, ?LAZY(json_map(json_term(N div 4)))}
    ]).

json_term_mp() ->
	?SIZED(N, json_term_mp(N)).

json_term_mp(0) ->
    oneof([
      json_integer(),
      json_float(),
      json_number(),
      json_string(),
      json_mp_atom()
    ]);
json_term_mp(N) ->
	frequency([
		{1, json_term_mp(0)},
		{N, ?LAZY(list(json_term_mp(N div 4)))},
		{N, ?LAZY(json_map(json_term_mp(N div 4)))}
	]).

normalize(L) when is_list(L) -> [normalize(X) || X <- L];
normalize(M) when is_map(M) ->
    case [{normalize(K), normalize(V)} || {K, V} <- maps:to_list(M)] of
      [] -> [{}];
      X -> X
    end;
normalize(X) -> X.

iso_jsx(T) ->
    E = jsx:encode(T),
    D = jsx:decode(E),
    equals(D, normalize(T)).

iso_msgpack(T) ->
    Opts = [{format, map}],
    E = msgpack:pack(T, Opts),
    {ok, D} = msgpack:unpack(E, Opts),
    D =:= T.

prop_iso_mp() ->
    ?FORALL(T, json_term_mp(),
        iso_msgpack(T)).
        
prop_string_mp() ->
    ?FORALL(T, json_string(),
        iso_msgpack(T)).

prop_iso() ->
    ?FORALL(T, json_term(),
      iso_jsx(T)).

prop_string_iso() ->
    ?FORALL(S, json_string(),
      iso_jsx(S)).

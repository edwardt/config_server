%% -------------------------------------------------------------------
%%
%% riak_core: Core Riak Application
%%
%% Copyright (c) 2007-2012 Basho Technologies, Inc.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------

-module(app_helper).

-export([get_env/1,
         get_env/2,
         get_env/3,
         get_prop_or_env/3,
         get_prop_or_env/4,
	 get_config_from_list/2,
	 get_config_from_list/3,
         try_envs/1,
         try_envs/2,
	 ensure_app_started/1,
	 ensure_app_stopped/1, 
	 ensure_config_loaded/1,
	 ensure_config_unloaded/1,
	 os_now/0]).

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.

%% ===================================================================
%% Public API
%% ===================================================================

%% @spec get_config_from_list(atom(), list())-> {ok, term()}.
%% @doc Get config value from external config file which is as list
%% @end.
get_config_from_list(Key, List) when is_atom(Key), is_list(List) ->
   V = fun(What, R) -> 
	  hd([ Value || {Key, Value} <- R, Key =:= What]) 
       end,
   
   try V(Key,List) of
         Val -> Val
   catch 
	 error:_ -> {error, {Key, not_found}}  
   end.	

get_config_from_list(Key,List,required) when is_atom(Key), is_list(List)->
   get_config_from_list(Key, List); 
get_config_from_list(Key,List,Default) when is_atom(Key), is_list(List)->
   case get_config_from_list(Key, List) of
        {error, {Key, not_found}} -> Default;
	Val -> Val
   end.
   

%% @spec get_env(App :: atom()) -> [{Key :: atom(), Value :: term()}]
%% @doc Retrieve all Key/Value pairs in the env for the specified app.
get_env(App) ->
    application:get_all_env(App).

%% @spec get_env(App :: atom(), Key :: atom()) -> term()
%% @doc The official way to get a value from the app's env.
%%      Will return the 'undefined' atom if that key is unset.
get_env(App, Key) ->
    get_env(App, Key, undefined).

%% @spec get_env(App :: atom(), Key :: atom(), Default :: term()) -> term()
%% @doc The official way to get a value from this application's env.
%%      Will return Default if that key is unset.
get_env(App, Key, Default) ->
    case application:get_env(App, Key) of
	{ok, Value} ->
            {ok, Value};
        _ ->
            Default
    end.

%% @doc Retrieve value for Key from Properties if it exists, otherwise
%%      return from the application's env.
-spec get_prop_or_env(atom(), [{atom(), term()}], atom()) -> term().
get_prop_or_env(Key, Properties, App) ->
    get_prop_or_env(Key, Properties, App, undefined).

%% @doc Return the value for Key in Properties if it exists, otherwise return
%%      the value from the application's env, or Default.
-spec get_prop_or_env(atom(), [{atom(), term()}], atom(), term()) -> term().
get_prop_or_env(Key, Properties, App, Default) ->
    case proplists:get_value(Key, Properties) of
        undefined ->
            get_env(App, Key, Default);
        Value ->
            Value
    end.

%% @doc Like `get_env' but try multiple `{App, Key}' combos before
%%      returning `{default, Default}'.  The return value is `{App,
%%      Key, Value}' so that the caller may distinguish where the
%%      value came from.  This is useful for scenarios when the config
%%      app/key has changed between releases and you need to check for
%%      both.
-spec try_envs([{atom(), atom()}], term()) -> {atom(), atom(), term()}.
try_envs([{App, Key}|T], Default) ->
    case get_env(App, Key) of
        undefined ->
            try_envs(T, Default);
        {ok, Value} ->
            {App, Key, Value}
    end;
try_envs([], Default) ->
    {default, Default}.

try_envs(Pairs) ->
    try_envs(Pairs, undefined).

ensure_app_started(App) when is_atom(App)->
  case application:start(App) of
	ok -> ok;
	{error, {already_started, App}} -> ok;
  	{error, R} -> {error, R}
  end;
ensure_app_started(_)-> {error, badarg}.

ensure_app_stopped(App) when is_atom(App)->
  case application:stop(App) of
	ok -> ok;
	{error,{not_started,App}} -> ok;
	{error, R} -> {error, R} 
  end;
ensure_app_stopped(_)-> {error, badarg}.

ensure_config_loaded(Name)->
  case application:load(Name) of
	ok -> ok;
	{error,{already_loaded, _}} -> ok;
  	{error, R} -> {error, R}
  end.

ensure_config_unloaded(Name)->
  case application:unload(Name) of
	ok -> ok;
	{error, {already_unloaded, _}} -> ok;
  	{error, R} -> {error, R}
  end.

os_now()->
  os:timestamp().

%% ===================================================================
%% EUnit tests
%% ===================================================================
-ifdef(TEST).

app_helper_test_() ->
    { setup,
      fun setup/0,
      fun cleanup/1,
      [
       {"Should get default val",fun get_prop_or_env_default_value_test_case/0},
       {"Should report undefined key from proo or env",fun get_prop_or_env_undefined_value_test_case/0},
       {"Should either get from env",fun get_prop_or_env_from_env_test_case/0},
       {"Should either get value proplist",fun get_prop_or_env_from_prop_test_case/0},
       {"Should get default values from proplist",fun get_prop_or_env_from_prop_with_default_test_case/0},
       {"Should try to get environment settings",fun try_envs_test_case/0},
       {"Should get config val", 
	  fun get_config_value_test_case/0},
       {"Should report not_found wrong config key", 
	  fun get_config_value_nokey_test_case/0},
       {"Should get required config value", 
	  fun get_config_value_required_key_test_case/0},
       {"Should error on missing required config value", 
	  fun get_config_value_required_miss_value_test_case/0},
       {"Should get default config val", 
	  fun get_config_value_defaultValue_test_case/0}
      ]
    }.

setup() ->
    application:set_env(bogus_app, envkeyone, value),
    application:set_env(bogus_app, envkeytwo, valuetwo).

cleanup(_Ctx) ->
    ok.

get_prop_or_env_default_value_test_case() ->
    ?assertEqual(default, get_prop_or_env(key, [], bogus, default)).

get_prop_or_env_undefined_value_test_case() ->
    ?assertEqual(undefined, get_prop_or_env(key, [], bogus)).

get_prop_or_env_from_env_test_case() ->
    ?assertEqual({ok,value}, get_prop_or_env(envkeyone, [], bogus_app)).

get_prop_or_env_from_prop_test_case() ->
    Properties = [{envkeyone, propvalue}],
    ?assertEqual(propvalue, get_prop_or_env(envkeyone, Properties, bogus_app)).

get_prop_or_env_from_prop_with_default_test_case() ->
    Properties = [{envkeyone, propvalue}],
    ?assertEqual(propvalue, get_prop_or_env(envkeyone, Properties, bogus_app, default)).

try_envs_test_case() ->
    Val = try_envs([{noapp, nokey}, {bogus_app, envkeyone}], failed),
    ?assertEqual({bogus_app, envkeyone, value}, Val),
    Val2 = try_envs([{bogus_app, envkeytwo}, {noapp, nokey}], failed),
    ?assertEqual({bogus_app, envkeytwo, valuetwo}, Val2),
    Val3 = try_envs([{noapp, nokey}, {blah, blah}], default),
    ?assertEqual({default, default}, Val3).


get_config_value_test_case() ->
    CfgList = [{a,1},{b,2},{c,3},{d,[{d1,4}]}],
    V = get_config_from_list(a, CfgList),
    V1 = get_config_from_list(d, CfgList),
    ?assertEqual(1,V),
    ?assertEqual([{d1,4}],V1). 


get_config_value_nokey_test_case() ->
    CfgList = [{a,1},{b,2},{c,3},{d,[{d1,4}]}],
    V = get_config_from_list(e, CfgList),
    ?assertEqual({error,{e, not_found}},V). 

   
get_config_value_required_key_test_case()->
    CfgList = [{a,1},{b,2},{c,3},{d,[{d1,4}]}],
    V = get_config_from_list(c, CfgList),
    ?assertEqual(3,V).    

get_config_value_required_miss_value_test_case()->
    CfgList = [{a,1},{b,2},{c,3},{d,[{d1,4}]}],
    V = get_config_from_list(e, CfgList),
    ?assertEqual({error,{e, not_found}},V). 

get_config_value_defaultValue_test_case() ->
    CfgList = [{a,1},{b,2},{c,3},{d,[{d1,4}]}],
    V = get_config_from_list(e, CfgList, 123),
    ?assertEqual(123,V). 


-endif.

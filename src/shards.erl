%%%-------------------------------------------------------------------
%%% @doc
%%% This is the main module, which contains all Shards API functions.
%%% This is a wrapper on top of `shards_local' and `shards_dist'.
%%%
%%% @see shards_local.
%%% @see shards_dist.
%%% @end
%%%-------------------------------------------------------------------
-module(shards).

-behaviour(application).

%% Application callbacks and functions
-export([
  start/0, start/2,
  stop/0, stop/1
]).

%% ETS API
-export([
  all/0,
  delete/1, delete/2,
  delete_object/2,
  delete_all_objects/1,
  file2tab/1, file2tab/2,
  first/1,
  foldl/3,
  foldr/3,
  from_dets/2,
  fun2ms/1,
  give_away/3,
  i/0, i/1,
  info/1, info/2,
  info_shard/2, info_shard/3,
  init_table/2,
  insert/2,
  insert_new/2,
  is_compiled_ms/1,
  last/1,
  lookup/2,
  lookup_element/3,
  match/2, match/3, match/1,
  match_delete/2,
  match_object/2, match_object/3, match_object/1,
  match_spec_compile/1,
  match_spec_run/2,
  member/2,
  new/2,
  next/2,
  prev/2,
  rename/2,
  repair_continuation/2,
  safe_fixtable/2,
  select/2, select/3, select/1,
  select_count/2,
  select_delete/2,
  select_reverse/2, select_reverse/3, select_reverse/1,
  setopts/2,
  slot/2,
  tab2file/2, tab2file/3,
  tab2list/1,
  tabfile_info/1,
  table/1, table/2,
  test_ms/2,
  take/2,
  to_dets/2,
  update_counter/3, update_counter/4,
  update_element/3
]).

%% Distributed API
-export([
  join/2,
  leave/2,
  get_nodes/1,
  pick_node/2
]).

-export([
  metadata/1,
  state/1,
  local_state/1,
  dist_state/1,
  module/1,
  n_shards/1,
  pick_shard_fun/1,
  tab_type/1,
  list/1
]).

%%%===================================================================
%%% Types & Macros
%%%===================================================================

%% @type metadata() = shards_local:state().
-type metadata() :: {
  module(),
  shards_local:state(),
  shards_dist:state()
}.

%% @type state() = {
%%  LocalState :: shards_local:state(),
%%  DistState  :: shards_dist:state()
%% }.
%%
%% Defines the `shards' distributed state:
%% <ul>
%% <li>`PickNode': Function callback to pick/compute the node.</li>
%% <li>`TableType': Table type.</li>
%% </ul>
-type state() :: {
  LocalState :: shards_local:state(),
  DistState  :: shards_dist:state()
}.

%% @type continuation() = shards_local:continuation().
-type continuation() :: shards_local:continuation().

-export_type([
  metadata/0,
  state/0,
  continuation/0
]).

%% Macro to get the default module to use: `shards_local'.
-define(SHARDS, shards_local).

%%%===================================================================
%%% Application callbacks and functions
%%%===================================================================

%% @doc Starts `shards' application.
-spec start() -> {ok, _} | {error, term()}.
start() ->
  application:ensure_all_started(shards).

%% @doc Stops `shards' application.
-spec stop() -> ok | {error, term()}.
stop() ->
  application:stop(shards).

%% @hidden
start(_StartType, _StartArgs) ->
  shards_sup:start_link().

%% @hidden
stop(_State) ->
  ok.

%%%===================================================================
%%% Shards/ETS API
%%%===================================================================

%% @equiv shards_local:all()
all() ->
  ?SHARDS:all().

%% @doc
%% Wrapper to `shards_local:delete/1' and `shards_dist:delete/1'.
%%
%% @see shards_local:delete/1.
%% @see shards_dist:delete/1.
%% @end
-spec delete(Tab :: atom()) -> true.
delete(Tab) ->
  {Module, _, _} = metadata(Tab),
  Module:delete(Tab).

%% @doc
%% Wrapper to `shards_local:delete/3' and `shards_dist:delete/3'.
%%
%% @see shards_local:delete/3.
%% @see shards_dist:delete/3.
%% @end
-spec delete(Tab, Key) -> true when
  Tab   :: atom(),
  Key   :: term().
delete(Tab, Key) ->
  call(Tab, delete, [Tab, Key]).

%% @doc
%% Wrapper to `shards_local:delete_all_objects/2' and
%% `shards_dist:delete_all_objects/2'.
%%
%% @see shards_local:delete_all_objects/2.
%% @see shards_dist:delete_all_objects/2
%% @end
-spec delete_all_objects(Tab :: atom()) -> true.
delete_all_objects(Tab) ->
  call(Tab, delete_all_objects, [Tab]).

%% @doc
%% Wrapper to `shards_local:delete_object/3' and `shards_dist:delete_object/3'.
%%
%% @see shards_local:delete_object/3.
%% @see shards_dist:delete_object/3.
%% @end
-spec delete_object(Tab, Object) -> true when
  Tab    :: atom(),
  Object :: tuple().
delete_object(Tab, Object) ->
  call(Tab, delete_object, [Tab, Object]).

%% @equiv shards_local:file2tab(Filenames)
file2tab(Filenames) ->
  ?SHARDS:file2tab(Filenames).

%% @equiv shards_local:file2tab(Filenames, Options)
file2tab(Filenames, Options) ->
  ?SHARDS:file2tab(Filenames, Options).

%% @doc
%% Wrapper to `shards_local:first/2' and `shards_dist:first/2'.
%%
%% @see shards_local:first/2.
%% @see shards_dist:first/2.
%% @end
-spec first(Tab :: atom()) -> Key :: term() | '$end_of_table'.
first(Tab) ->
  call(Tab, first, [Tab]).

%% @doc
%% Wrapper to `shards_local:foldl/4' and `shards_dist:foldl/4'.
%%
%% @see shards_local:foldl/4.
%% @see shards_dist:foldl/4.
%% @end
-spec foldl(Function, Acc0, Tab) -> Acc1 when
  Function :: fun((Element :: term(), AccIn) -> AccOut),
  Tab      :: atom(),
  Acc0     :: term(),
  Acc1     :: term(),
  AccIn    :: term(),
  AccOut   :: term().
foldl(Function, Acc0, Tab) ->
  call(Tab, foldl, [Function, Acc0, Tab]).

%% @doc
%% Wrapper to `shards_local:foldr/4' and `shards_dist:foldr/4'.
%%
%% @see shards_local:foldr/4.
%% @see shards_dist:foldr/4.
%% @end
-spec foldr(Function, Acc0, Tab) -> Acc1 when
  Function :: fun((Element :: term(), AccIn) -> AccOut),
  Tab      :: atom(),
  Acc0     :: term(),
  Acc1     :: term(),
  AccIn    :: term(),
  AccOut   :: term().
foldr(Function, Acc0, Tab) ->
  call(Tab, foldr, [Function, Acc0, Tab]).

%% @doc
%% Wrapper to `shards_local:from_dets/2' and `shards_dist:from_dets/2'.
%%
%% @see shards_local:from_dets/2.
%% @see shards_dist:from_dets/2.
%% @end
-spec from_dets(Tab, DetsTab) -> true when
  Tab     :: atom(),
  DetsTab :: dets:tab_name().
from_dets(Tab, DetsTab) ->
  {Module, _, _} = metadata(Tab),
  Module:from_dets(Tab, DetsTab).

%% @doc
%% <p><font color="red"><b>WARNING:</b> Please use `shards_local:fun2ms/1'
%% instead.</font></p>
%%
%% Since this function uses `parse_transform', it isn't possible
%% to call `shards_local:fun2ms/1' from `shards'. Besides, it isn't
%% necessary, the effect is the same as you call directly
%% `shards_local:fun2ms/1' from you code.
%%
%% @see ets:fun2ms/1.
%% @end
fun2ms(_LiteralFun) ->
  throw(unsupported_operation).

%% @doc
%% Wrapper to `shards_local:give_away/4' and `shards_dist:give_away/4'.
%%
%% @see shards_local:give_away/4.
%% @see shards_dist:give_away/4.
%% @end
-spec give_away(Tab, Pid, GiftData) -> true when
  Tab      :: atom(),
  Pid      :: pid(),
  GiftData :: term().
give_away(Tab, Pid, GiftData) ->
  call(Tab, give_away, [Tab, Pid, GiftData]).

%% @equiv shards_local:i()
i() ->
  ?SHARDS:i().

%% @doc
%% Wrapper to `shards_local:i/1' and `shards_dist:i/1'.
%%
%% @see shards_local:i/1.
%% @see shards_dist:i/1.
%% @end
-spec i(Tab :: atom()) -> ok.
i(Tab) ->
  {Module, _, _} = metadata(Tab),
  Module:i(Tab).

%% @doc
%% Wrapper to `shards_local:info/2' and `shards_dist:info/2'.
%%
%% @see shards_local:info/2.
%% @see shards_dist:info/2.
%% @end
-spec info(Tab) -> Result when
  Tab      :: atom(),
  Result   :: [InfoList],
  InfoList :: [term() | undefined].
info(Tab) ->
  call(Tab, info, [Tab]).

%% @doc
%% Wrapper to `shards_local:info/3' and `shards_dist:info/3'.
%%
%% @see shards_local:info/3.
%% @see shards_dist:info/3.
%% @end
-spec info(Tab, Item) -> Result when
  Tab    :: atom(),
  Item   :: atom(),
  Result :: [Value],
  Value  :: [term() | undefined].
info(Tab, Item) ->
  case whereis(Tab) of
    undefined -> undefined;
    _         -> call(Tab, info, [Tab, Item])
  end.

%% @doc
%% Wrapper to `shards_local:info_shard/2' and `shards_dist:info_shard/2'.
%%
%% @see shards_local:info_shard/2.
%% @see shards_dist:info_shard/2.
%% @end
-spec info_shard(Tab, Shard) -> Result when
  Tab    :: atom(),
  Shard  :: non_neg_integer(),
  Result :: [term()] | undefined.
info_shard(Tab, Shard) ->
  {Module, _, _} = metadata(Tab),
  Module:info_shard(Tab, Shard).

%% @doc
%% Wrapper to `shards_local:info_shard/3' and `shards_dist:info_shard/3'.
%%
%% @see shards_local:info_shard/3.
%% @see shards_dist:info_shard/3.
%% @end
-spec info_shard(Tab, Shard, Item) -> Result when
  Tab    :: atom(),
  Shard  :: non_neg_integer(),
  Item   :: atom(),
  Result :: term() | undefined.
info_shard(Tab, Shard, Item) ->
  {Module, _, _} = metadata(Tab),
  Module:info_shard(Tab, Shard, Item).

%% @doc
%% Wrapper to `shards_local:init_table/3' and `shards_dist:init_table/3'.
%%
%% @see shards_local:init_table/3.
%% @see shards_dist:init_table/3.
%% @end
-spec init_table(Tab, InitFun) -> true when
  Tab     :: atom(),
  InitFun :: fun((Arg) -> Res),
  Arg     :: read | close,
  Res     :: end_of_input | {Objects :: [term()], InitFun} | term().
init_table(Tab, InitFun) ->
  call(Tab, init_table, [Tab, InitFun]).

%% @doc
%% Wrapper to `shards_local:insert/3' and `shards_dist:insert/3'.
%%
%% @see shards_local:insert/3.
%% @see shards_dist:insert/3.
%% @end
-spec insert(Tab, ObjOrObjL) -> true when
  Tab       :: atom(),
  ObjOrObjL :: tuple() | [tuple()].
insert(Tab, ObjectOrObjects) ->
  call(Tab, insert, [Tab, ObjectOrObjects]).

%% @doc
%% Wrapper to `shards_local:insert_new/3' and `shards_dist:insert_new/3'.
%%
%% @see shards_local:insert_new/3.
%% @see shards_dist:insert_new/3.
%% @end
-spec insert_new(Tab, ObjOrObjL) -> Result when
  Tab       :: atom(),
  ObjOrObjL :: tuple() | [tuple()],
  Result    :: boolean() | [boolean()].
insert_new(Tab, ObjectOrObjects) ->
  call(Tab, insert_new, [Tab, ObjectOrObjects]).

%% @equiv shards_local:is_compiled_ms(Term)
is_compiled_ms(Term) ->
  ?SHARDS:is_compiled_ms(Term).

%% @doc
%% Wrapper to `shards_local:last/2' and `shards_dist:last/2'.
%%
%% @see shards_local:last/2.
%% @see shards_dist:last/2.
%% @end
-spec last(Tab :: atom()) -> Key :: term() | '$end_of_table'.
last(Tab) ->
  call(Tab, last, [Tab]).

%% @doc
%% Wrapper to `shards_local:lookup/3' and `shards_dist:lookup/3'.
%%
%% @see shards_local:lookup/3.
%% @see shards_dist:lookup/3.
%% @end
-spec lookup(Tab, Key) -> Result when
  Tab    :: atom(),
  Key    :: term(),
  Result :: [tuple()].
lookup(Tab, Key) ->
  call(Tab, lookup, [Tab, Key]).

%% @doc
%% Wrapper to `shards_local:lookup_element/4' and
%% `shards_dist:lookup_element/4'.
%%
%% @see shards_local:lookup_element/4.
%% @see shards_dist:lookup_element/4.
%% @end
-spec lookup_element(Tab, Key, Pos) -> Elem when
  Tab   :: atom(),
  Key   :: term(),
  Pos   :: pos_integer(),
  Elem  :: term() | [term()].
lookup_element(Tab, Key, Pos) ->
  call(Tab, lookup_element, [Tab, Key, Pos]).

%% @doc
%% Wrapper to `shards_local:match/3' and `shards_dist:match/3'.
%%
%% @see shards_local:match/3.
%% @see shards_dist:match/3.
%% @end
-spec match(Tab, Pattern) -> [Match] when
  Tab     :: atom(),
  Pattern :: ets:match_pattern(),
  Match   :: [term()].
match(Tab, Pattern) ->
  call(Tab, match, [Tab, Pattern]).

%% @doc
%% Wrapper to `shards_local:match/4' and `shards_dist:match/4'.
%%
%% @see shards_local:match/4.
%% @see shards_dist:match/4.
%% @end
-spec match(Tab, Pattern, Limit) -> Response when
  Tab          :: atom(),
  Pattern      :: ets:match_pattern(),
  Limit        :: pos_integer(),
  Match        :: term(),
  Continuation :: continuation(),
  Response     :: {[Match], Continuation} | '$end_of_table'.
match(Tab, Pattern, Limit) ->
  call(Tab, match, [Tab, Pattern, Limit]).

%% @doc
%% Wrapper to `shards_local:match/2' and `shards_dist:match/2'.
%%
%% @see shards_local:match/2.
%% @see shards_dist:match/2.
%% @end
-spec match(Continuation) -> Response when
  Match        :: term(),
  Continuation :: continuation(),
  Response     :: {[Match], Continuation} | '$end_of_table'.
match(Continuation) ->
  [Tab | _] = tuple_to_list(Continuation),
  call(Tab, match, [Continuation]).

%% @doc
%% Wrapper to `shards_local:match_delete/3' and `shards_dist:match_delete/3'.
%%
%% @see shards_local:match_delete/3.
%% @see shards_dist:match_delete/3.
%% @end
-spec match_delete(Tab, Pattern) -> true when
  Tab     :: atom(),
  Pattern :: ets:match_pattern().
match_delete(Tab, Pattern) ->
  call(Tab, match_delete, [Tab, Pattern]).

%% @doc
%% Wrapper to `shards_local:match_object/3' and `shards_dist:match_object/3'.
%%
%% @see shards_local:match_object/3.
%% @see shards_dist:match_object/3.
%% @end
-spec match_object(Tab, Pattern) -> [Object] when
  Tab     :: atom(),
  Pattern :: ets:match_pattern(),
  Object  :: tuple().
match_object(Tab, Pattern) ->
  call(Tab, match_object, [Tab, Pattern]).

%% @doc
%% Wrapper to `shards_local:match_object/4' and `shards_dist:match_object/4'.
%%
%% @see shards_local:match_object/4.
%% @see shards_dist:match_object/4.
%% @end
-spec match_object(Tab, Pattern, Limit) -> Response when
  Tab          :: atom(),
  Pattern      :: ets:match_pattern(),
  Limit        :: pos_integer(),
  Match        :: term(),
  Continuation :: continuation(),
  Response     :: {[Match], Continuation} | '$end_of_table'.
match_object(Tab, Pattern, Limit) ->
  call(Tab, match_object, [Tab, Pattern, Limit]).

%% @doc
%% Wrapper to `shards_local:match_object/2' and `shards_dist:match_object/2'.
%%
%% @see shards_local:match_object/2.
%% @see shards_dist:match_object/2.
%% @end
-spec match_object(Continuation) -> Response when
  Match        :: term(),
  Continuation :: continuation(),
  Response     :: {[Match], Continuation} | '$end_of_table'.
match_object(Continuation) ->
  [Tab | _] = tuple_to_list(Continuation),
  call(Tab, match_object, [Continuation]).

%% @equiv shards_local:match_spec_compile(MatchSpec)
match_spec_compile(MatchSpec) ->
  ?SHARDS:match_spec_compile(MatchSpec).

%% @equiv shards_local:match_spec_run(List, CompiledMatchSpec)
match_spec_run(List, CompiledMatchSpec) ->
  ?SHARDS:match_spec_run(List, CompiledMatchSpec).

%% @doc
%% Wrapper to `shards_local:member/3' and `shards_dist:member/3'.
%%
%% @see shards_local:member/3.
%% @see shards_dist:member/3.
%% @end
-spec member(Tab :: atom(), Key :: term()) -> boolean().
member(Tab, Key) ->
  call(Tab, member, [Tab, Key]).

%% @equiv shards_local:new(Name, Options)
new(Name, Options) ->
  ?SHARDS:new(Name, Options).

%% @doc
%% Wrapper to `shards_local:next/3' and `shards_dist:next/3'.
%%
%% @see shards_local:next/3.
%% @see shards_dist:next/3.
%% @end
-spec next(Tab, Key1) -> Key2 | '$end_of_table' when
  Tab   :: atom(),
  Key1  :: term(),
  Key2  :: term().
next(Tab, Key1) ->
  call(Tab, next, [Tab, Key1]).

%% @doc
%% Wrapper to `shards_local:prev/3' and `shards_dist:prev/3'.
%%
%% @see shards_local:prev/3.
%% @see shards_dist:prev/3.
%% @end
-spec prev(Tab, Key1) -> Key2 | '$end_of_table' when
  Tab   :: atom(),
  Key1  :: term(),
  Key2  :: term().
prev(Tab, Key1) ->
  call(Tab, prev, [Tab, Key1]).

%% @doc
%% Wrapper to `shards_local:rename/3' and `shards_dist:rename/3'.
%%
%% @see shards_local:rename/3.
%% @see shards_dist:rename/3.
%% @end
-spec rename(Tab, Name) -> Name when
  Tab  :: atom(),
  Name :: atom().
rename(Tab, Name) ->
  call(Tab, rename, [Tab, Name]).

%% @doc
%% Wrapper to `shards_local:repair_continuation/3' and
%% `shards_dist:repair_continuation/3'.
%%
%% @see shards_local:repair_continuation/3.
%% @see shards_dist:repair_continuation/3.
%% @end
-spec repair_continuation(Continuation, MatchSpec) -> Continuation when
  Continuation :: continuation(),
  MatchSpec    :: ets:match_spec().
repair_continuation(Continuation, MatchSpec) ->
  [Tab | _] = tuple_to_list(Continuation),
  call(Tab, repair_continuation, [Continuation, MatchSpec]).

%% @doc
%% Wrapper to `shards_local:i/1' and `shards_dist:i/1'.
%%
%% @see shards_local:i/1.
%% @see shards_dist:i/1.
%% @end
-spec safe_fixtable(Tab, Fix) -> true when
  Tab :: atom(),
  Fix :: boolean().
safe_fixtable(Tab, Fix) ->
  call(Tab, safe_fixtable, [Tab, Fix]).

%% @doc
%% Wrapper to `shards_local:select/3' and `shards_dist:select/3'.
%%
%% @see shards_local:select/3.
%% @see shards_dist:select/3.
%% @end
-spec select(Tab, MatchSpec) -> [Match] when
  Tab       :: atom(),
  MatchSpec :: ets:match_spec(),
  Match     :: term().
select(Tab, MatchSpec) ->
  call(Tab, select, [Tab, MatchSpec]).

%% @doc
%% Wrapper to `shards_local:select/4' and `shards_dist:select/4'.
%%
%% @see shards_local:select/4.
%% @see shards_dist:select/4.
%% @end
-spec select(Tab, MatchSpec, Limit) -> Response when
  Tab          :: atom(),
  MatchSpec    :: ets:match_spec(),
  Limit        :: pos_integer(),
  Match        :: term(),
  Continuation :: continuation(),
  Response     :: {[Match], Continuation} | '$end_of_table'.
select(Tab, MatchSpec, Limit) ->
  call(Tab, select, [Tab, MatchSpec, Limit]).

%% @doc
%% Wrapper to `shards_local:select/2' and `shards_dist:select/2'.
%%
%% @see shards_local:select/2.
%% @see shards_dist:select/2.
%% @end
-spec select(Continuation) -> Response when
  Match        :: term(),
  Continuation :: continuation(),
  Response     :: {[Match], Continuation} | '$end_of_table'.
select(Continuation) ->
  [Tab | _] = tuple_to_list(Continuation),
  call(Tab, select, [Continuation]).

%% @doc
%% Wrapper to `shards_local:select_count/3' and `shards_dist:select_count/3'.
%%
%% @see shards_local:select_count/3.
%% @see shards_dist:select_count/3.
%% @end
-spec select_count(Tab, MatchSpec) -> NumMatched when
  Tab        :: atom(),
  MatchSpec  :: ets:match_spec(),
  NumMatched :: non_neg_integer().
select_count(Tab, MatchSpec) ->
  call(Tab, select_count, [Tab, MatchSpec]).

%% @doc
%% Wrapper to `shards_local:select_delete/3' and `shards_dist:select_delete/3'.
%%
%% @see shards_local:select_delete/3.
%% @see shards_dist:select_delete/3.
%% @end
-spec select_delete(Tab, MatchSpec) -> NumDeleted when
  Tab        :: atom(),
  MatchSpec  :: ets:match_spec(),
  NumDeleted :: non_neg_integer().
select_delete(Tab, MatchSpec) ->
  call(Tab, select_delete, [Tab, MatchSpec]).

%% @doc
%% Wrapper to `shards_local:select_reverse/3' and
%% `shards_dist:select_reverse/3'.
%%
%% @see shards_local:select_reverse/3.
%% @see shards_dist:select_reverse/3.
%% @end
-spec select_reverse(Tab, MatchSpec) -> [Match] when
  Tab       :: atom(),
  MatchSpec :: ets:match_spec(),
  Match     :: term().
select_reverse(Tab, MatchSpec) ->
  call(Tab, select_reverse, [Tab, MatchSpec]).

%% @doc
%% Wrapper to `shards_local:select_reverse/4' and
%% `shards_dist:select_reverse/4'.
%%
%% @see shards_local:select_reverse/4.
%% @see shards_dist:select_reverse/4.
%% @end
-spec select_reverse(Tab, MatchSpec, Limit) -> Response when
  Tab          :: atom(),
  MatchSpec    :: ets:match_spec(),
  Limit        :: pos_integer(),
  Match        :: term(),
  Continuation :: continuation(),
  Response     :: {[Match], Continuation} | '$end_of_table'.
select_reverse(Tab, MatchSpec, Limit) ->
  call(Tab, select_reverse, [Tab, MatchSpec, Limit]).

%% @doc
%% Wrapper to `shards_local:select_reverse/2' and
%% `shards_dist:select_reverse/2'.
%%
%% @see shards_local:select_reverse/2.
%% @see shards_dist:select_reverse/2.
%% @end
-spec select_reverse(Continuation) -> Response when
  Match        :: term(),
  Continuation :: continuation(),
  Response     :: {[Match], Continuation} | '$end_of_table'.
select_reverse(Continuation) ->
  [Tab | _] = tuple_to_list(Continuation),
  call(Tab, select_reverse, [Continuation]).

%% @doc
%% Wrapper to `shards_local:setopts/3' and `shards_dist:setopts/3'.
%%
%% @see shards_local:setopts/3.
%% @see shards_dist:setopts/3.
%% @end
-spec setopts(Tab, Opts) -> boolean() when
  Tab      :: atom(),
  Opts     :: Opt | [Opt],
  Opt      :: {heir, pid(), HeirData} | {heir, none},
  HeirData :: term().
setopts(Tab, Opts) ->
  call(Tab, setopts, [Tab, Opts]).

%% @doc
%% Wrapper to `shards_local:slot/3' and `shards_dist:slot/3'.
%%
%% @see shards_local:slot/3.
%% @see shards_dist:slot/3.
%% @end
-spec slot(Tab, I) -> [Object] | '$end_of_table' when
  Tab    :: atom(),
  I      :: non_neg_integer(),
  Object :: tuple().
slot(Tab, I) ->
  call(Tab, slot, [Tab, I]).

%% @doc
%% Wrapper to `shards_local:tab2file/3' and `shards_dist:tab2file/3'.
%%
%% @see shards_local:tab2file/3.
%% @see shards_dist:tab2file/3.
%% @end
-spec tab2file(Tab, Filenames) -> Response when
  Tab       :: atom(),
  Filenames :: [file:name()],
  ShardTab  :: atom(),
  ShardRes  :: ok | {error, Reason :: term()},
  Response  :: [{ShardTab, ShardRes}].
tab2file(Tab, Filenames) ->
  call(Tab, tab2file, [Tab, Filenames]).

%% @doc
%% Wrapper to `shards_local:tab2file/4' and `shards_dist:tab2file/4'.
%%
%% @see shards_local:tab2file/4.
%% @see shards_dist:tab2file/4.
%% @end
-spec tab2file(Tab, Filenames, Options) -> Response when
  Tab       :: atom(),
  Filenames :: [file:name()],
  Options   :: [Option],
  Option    :: {extended_info, [ExtInfo]} | {sync, boolean()},
  ExtInfo   :: md5sum | object_count,
  ShardTab  :: atom(),
  ShardRes  :: ok | {error, Reason :: term()},
  Response  :: [{ShardTab, ShardRes}].
tab2file(Tab, Filenames, Options) ->
  call(Tab, tab2file, [Tab, Filenames, Options]).

%% @doc
%% Wrapper to `shards_local:tab2list/2' and `shards_dist:tab2list/2'.
%%
%% @see shards_local:tab2list/2.
%% @see shards_dist:tab2list/2.
%% @end
-spec tab2list(Tab) -> [Object] when
  Tab    :: atom(),
  Object :: tuple().
tab2list(Tab) ->
  call(Tab, tab2list, [Tab]).

%% @equiv shards_local:tabfile_info(Filename)
tabfile_info(Filename) ->
  ?SHARDS:tabfile_info(Filename).

%% @doc
%% Wrapper to `shards_local:table/2' and `shards_dist:table/2'.
%%
%% @see shards_local:table/2.
%% @see shards_dist:table/2.
%% @end
-spec table(Tab) -> [QueryHandle] when
  Tab         :: atom(),
  QueryHandle :: qlc:query_handle().
table(Tab) ->
  call(Tab, table, [Tab]).

%% @doc
%% Wrapper to `shards_local:table/3' and `shards_dist:table/3'.
%%
%% @see shards_local:table/3.
%% @see shards_dist:table/3.
%% @end
-spec table(Tab, Options) -> [QueryHandle] when
  Tab            :: atom(),
  QueryHandle    :: qlc:query_handle(),
  Options        :: [Option] | Option,
  Option         :: {n_objects, NObjects} | {traverse, TraverseMethod},
  NObjects       :: default | pos_integer(),
  MatchSpec      :: ets:match_spec(),
  TraverseMethod :: first_next | last_prev | select | {select, MatchSpec}.
table(Tab, Options) ->
  call(Tab, table, [Tab, Options]).

%% @equiv shards_local:test_ms(Tuple, MatchSpec)
test_ms(Tuple, MatchSpec) ->
  ?SHARDS:test_ms(Tuple, MatchSpec).

%% @doc
%% Wrapper to `shards_local:take/3' and `shards_dist:take/3'.
%%
%% @see shards_local:take/3.
%% @see shards_dist:take/3.
%% @end
-spec take(Tab, Key) -> [Object] when
  Tab    :: atom(),
  Key    :: term(),
  Object :: tuple().
take(Tab, Key) ->
  call(Tab, take, [Tab, Key]).

%% @doc
%% Wrapper to `shards_local:to_dets/2' and `shards_dist:to_dets/2'.
%%
%% @see shards_local:to_dets/2.
%% @see shards_dist:to_dets/2.
%% @end
-spec to_dets(Tab, DetsTab) -> DetsTab when
  Tab     :: atom(),
  DetsTab :: dets:tab_name().
to_dets(Tab, DetsTab) ->
  call(Tab, to_dets, [Tab, DetsTab]).

%% @doc
%% Wrapper to `shards_local:update_counter/4' and
%% `shards_dist:update_counter/4'.
%%
%% @see shards_local:update_counter/4.
%% @see shards_dist:update_counter/4.
%% @end
-spec update_counter(Tab, Key, UpdateOp) -> Result when
  Tab      :: atom(),
  Key      :: term(),
  UpdateOp :: term(),
  Result   :: integer().
update_counter(Tab, Key, UpdateOp) ->
  call(Tab, update_counter, [Tab, Key, UpdateOp]).

%% @doc
%% Wrapper to `shards_local:update_counter/5' and
%% `shards_dist:update_counter/5'.
%%
%% @see shards_local:update_counter/5.
%% @see shards_dist:update_counter/5.
%% @end
-spec update_counter(Tab, Key, UpdateOp, Default) -> Result when
  Tab      :: atom(),
  Key      :: term(),
  UpdateOp :: term(),
  Default  :: tuple(),
  Result   :: integer().
update_counter(Tab, Key, UpdateOp, Default) ->
  call(Tab, update_counter, [Tab, Key, UpdateOp, Default]).

%% @doc
%% Wrapper to `shards_local:update_element/4' and
%% `shards_dist:update_element/4'.
%%
%% @see shards_local:update_element/4.
%% @see shards_dist:update_element/4.
%% @end
-spec update_element(Tab, Key, ElementSpec) -> boolean() when
  Tab         :: atom(),
  Key         :: term(),
  Pos         :: pos_integer(),
  Value       :: term(),
  ElementSpec :: {Pos, Value} | [{Pos, Value}].
update_element(Tab, Key, ElementSpec) ->
  call(Tab, update_element, [Tab, Key, ElementSpec]).

%%%===================================================================
%%% Distributed API
%%%===================================================================

-spec join(Tab, Nodes) -> JoinedNodes when
  Tab         :: atom(),
  Nodes       :: [node()],
  JoinedNodes :: [node()].
join(Tab, Nodes) ->
  shards_dist:join(Tab, Nodes).

-spec leave(Tab, Nodes) -> LeavedNodes when
  Tab         :: atom(),
  Nodes       :: [node()],
  LeavedNodes :: [node()].
leave(Tab, Nodes) ->
  shards_dist:leave(Tab, Nodes).

-spec get_nodes(Tab) -> Nodes when
  Tab   :: atom(),
  Nodes :: [node()].
get_nodes(Tab) ->
  shards_dist:get_nodes(Tab).

-spec pick_node(Key, Nodes) -> Node when
  Key   :: term(),
  Nodes :: [node()],
  Node  :: node().
pick_node(Key, Nodes) ->
  shards_dist:pick_node(read, Key, Nodes).

%%%===================================================================
%%% Extended API
%%%===================================================================

%% @doc
%% Returns the stored table metadata.
%% <ul>
%% <li>`TabName': Table name.</li>
%% </ul>
%% @end
-spec metadata(TabName) -> Metadata when
  TabName  :: atom(),
  Metadata :: metadata().
metadata(TabName) ->
  ets:lookup_element(TabName, '$shards_meta', 2).

%% @doc
%% Returns the stored state information.
%% <ul>
%% <li>`TabName': Table name.</li>
%% </ul>
%% @end
-spec state(TabName) -> State when
  TabName :: atom(),
  State   :: state().
state(TabName) ->
  {_, Local, Dist} = metadata(TabName),
  {Local, Dist}.

%% @doc
%% Returns the stored local state information.
%% <ul>
%% <li>`TabName': Table name.</li>
%% </ul>
%% @end
-spec local_state(TabName) -> State when
  TabName :: atom(),
  State   :: shards_local:state().
local_state(TabName) ->
  shards_local:state(TabName).

%% @doc
%% Returns the stored distributed state information.
%% <ul>
%% <li>`TabName': Table name.</li>
%% </ul>
%% @end
-spec dist_state(TabName) -> State when
  TabName :: atom(),
  State   :: shards_dist:state().
dist_state(TabName) ->
  shards_dist:state(TabName).

%% @doc
%% Returns the set module.
%% <ul>
%% <li>`TabName': Table name.</li>
%% </ul>
%% @end
-spec module(TabName) -> Module when
  TabName :: atom(),
  Module  :: module().
module(TabName) when is_atom(TabName) ->
  {Module, _, _} = metadata(TabName),
  Module.

%% @doc
%% Returns the number of shards.
%% <ul>
%% <li>`TabNameOrState': Table name or State.</li>
%% </ul>
%% @end
-spec n_shards(TabNameOrState) -> NumShards when
  TabNameOrState :: shards_local:state() | atom(),
  NumShards      :: pos_integer().
n_shards({NumShards, _, _}) -> NumShards;
n_shards(TabName)           -> n_shards(local_state(TabName)).

%% @doc
%% Returns the function to pick/compute the shard.
%% <ul>
%% <li>`TabNameOrState': Table name or State.</li>
%% </ul>
%% @end
-spec pick_shard_fun(TabNameOrState) -> PickShardFun when
  TabNameOrState :: shards_local:state() | atom(),
  PickShardFun   :: shards_local:pick_shard_fun().
pick_shard_fun({_, KeygenFun, _}) -> KeygenFun;
pick_shard_fun(TabName)           -> tab_type(local_state(TabName)).

%% @doc
%% Returns the table type.
%% <ul>
%% <li>`TabNameOrState': Table name or State.</li>
%% </ul>
%% @end
-spec tab_type(TabNameOrState) -> Type when
  TabNameOrState :: shards_local:state() | atom(),
  Type           :: ets:type().
tab_type({_, _, Type}) -> Type;
tab_type(TabName)      -> tab_type(local_state(TabName)).

%% @doc
%% Returns the list of shard names associated to the given `TabName'.
%% The shard names that were created in the `shards:new/2,3' fun.
%% <ul>
%% <li>`TabName': Table name.</li>
%% </ul>
%% @end
-spec list(TabName) -> ShardTabNames when
  TabName       :: atom(),
  ShardTabNames :: [atom()].
list(TabName) ->
  shards_local:list(TabName, n_shards(TabName)).

%%%===================================================================
%%% Internal functions
%%%===================================================================

%% @private
call(Tab, Fun, Args) ->
  case metadata(Tab) of
    {shards_local, Local, _} ->
      apply(shards_local, Fun, Args ++ [Local]);
    {shards_dist, Local, Dist} ->
      apply(shards_dist, Fun, Args ++ [{Local, Dist}])
  end.

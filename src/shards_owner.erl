%%%-------------------------------------------------------------------
%%% @doc
%%% ETS owner.
%%% @end
%%%-------------------------------------------------------------------
-module(shards_owner).

-behaviour(gen_server).

%% API
-export([
  start_link/2,
  shard_name/2,
  give_away/3,
  setopts/2,
  stop/1
]).

%% gen_server callbacks
-export([
  init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3
]).

%%%===================================================================
%%% API
%%%===================================================================

%% @doc
%% Starts the ETS owner.
%%
%% <ul>
%% <li>`Name': Local name for ETS table, and also the name to register
%% the server under.</li>
%% <li>`Options': ETS options.</li>
%% </ul>
%% @end
-spec start_link(atom(), atom()) -> gen:start_ret().
start_link(Name, Options) ->
  gen_server:start_link({local, Name}, ?MODULE, [Name, Options], []).

-spec shard_name(atom(), non_neg_integer()) -> atom().
shard_name(Name, Shard) ->
  Bin = <<(atom_to_binary(Name, utf8))/binary, "_",
          (integer_to_binary(Shard))/binary>>,
  binary_to_atom(Bin, utf8).

-spec give_away(atom(), pid(), term()) -> boolean().
give_away(Name, Pid, GiftData) ->
  gen_server:call(Name, {give_away, Pid, GiftData}).

-spec setopts(atom(), [term()]) -> boolean().
setopts(Name, Options) ->
  gen_server:call(Name, {setopts, Options}).

-spec stop(atom()) -> ok.
stop(ShardName) ->
  true = exit(whereis(ShardName), normal),
  ok.

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%% @hidden
init([Name, [{restore, ShardTabs, Options}]]) ->
  {Name, Filename} = lists:keyfind(Name, 1, ShardTabs),
  {ok, _} = ets:file2tab(Filename, Options),
  {ok, #{name => Name, opts => []}};
init([Name, Options]) ->
  NewOpts = validate_options(Options),
  Name = ets:new(Name, NewOpts),
  {ok, #{name => Name, opts => NewOpts}}.

%% @private
validate_options(Options) ->
  Options1 = case lists:member(named_table, Options) of
    true -> Options;
    _    -> [named_table | Options]
  end,
  case lists:member(public, Options1) of
    true -> Options1;
    _    -> [public | Options1]
  end.

%% @hidden
handle_call({give_away, Pid, GiftData}, _From, #{name := Name} = State) ->
  Response = ets:give_away(Name, Pid, GiftData),
  {reply, Response, State};
handle_call({setopts, Options}, _From, #{name := Name} = State) ->
  Response = ets:setopts(Name, Options),
  {reply, Response, State};
handle_call(_Request, _From, State) ->
  {reply, ok, State}.

%% @hidden
handle_cast(_Request, State) ->
  {noreply, State}.

%% @hidden
handle_info(_Info, State) ->
  {noreply, State}.

%% @hidden
terminate(_Reason, _State) ->
  ok.

%% @hidden
code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

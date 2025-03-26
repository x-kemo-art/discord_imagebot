defmodule DiscordImagebot.ServerManager do
  use GenServer

  alias DiscordImagebot.ServerNode

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    :logger.debug("Starting server manager @ #{inspect(self())}")

    :ets.new(
      __MODULE__,
      [:named_table, :public, write_concurrency: true]
    )

    Process.flag(:trap_exit, true)

    {:ok, state}
  end

  def handle_call({:start_node, guild_id}, _from, state) do
    {:ok, pid} = ServerNode.start_link(guild_id)
    :ets.insert(__MODULE__, {guild_id, pid})
    state = Map.put(state, pid, guild_id)
    {:reply, pid, state}
  end

  def handle_info({:EXIT, pid, _reason}, state) do
    :logger.error("server node @ #{inspect(pid)} unexpectedly exited")

    state = remove_server_node_by_pid(state, pid)

    {:noreply, state}
  end

  defp remove_server_node_by_pid(state, pid) do
    case Map.get(state, pid) do
      nil ->
        state

      guild_id ->
        :ets.delete(__MODULE__, guild_id)
        Map.delete(state, pid)
    end
  end

  defp start_server_node(guild_id) do
    GenServer.call(__MODULE__, {:start_node, guild_id})
  end

  def get_guild_node(guild_id) do
    case :ets.lookup(__MODULE__, guild_id) do
      [{^guild_id, pid}] -> pid
      [] -> start_server_node(guild_id)
    end
  end
end

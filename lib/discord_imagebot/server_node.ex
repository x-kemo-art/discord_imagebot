defmodule DiscordImagebot.ServerNode do
  use GenServer
  defstruct guild_id: "", supervisor_pid: nil

  alias DiscordImagebot.MessageTask
  alias DiscordImagebot.ServerNode

  def start_link(guild_id) do
    GenServer.start_link(__MODULE__, %ServerNode{guild_id: guild_id})
  end

  def init(state) do
    :logger.debug("started server node @ #{inspect(self())}")
    Process.flag(:trap_exit, true)
    {:ok, supervisor_pid} = Task.Supervisor.start_link()
    {:ok, %{state | supervisor_pid: supervisor_pid}}
  end

  def handle_call({:msg_received, msg = %Nostrum.Struct.Message{}}, _from, state) do
    MessageTask.start_link(msg)
    {:reply, :ok, state}
  end

  def handle_info({:EXIT, _pid, :normal}, state), do: {:noreply, state}

  def handle_info({:EXIT, _pid, _reason}, state) do
    :logger.error("message processing failed for guild #{state.guild_id}")
    {:noreply, state}
  end

  def dispatch_msg(pid, msg) do
    GenServer.call(pid, {:msg_received, msg})
  end

  def handle_cast(:embed_complete, state) do
    :logger.info("embed job completed for #{state.guild_id}")
    {:noreply, state}
  end

  def finish_embed_job(pid) do
    GenServer.cast(pid, :embed_complete)
  end
end

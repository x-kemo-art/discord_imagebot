defmodule DiscordImagebot.Consumer do
  @behaviour Nostrum.Consumer

  alias DiscordImagebot.ServerManager
  alias DiscordImagebot.ServerNode

  def handle_event({:MESSAGE_CREATE, msg = %Nostrum.Struct.Message{}, _ws_state}) do
    if !msg.author.bot do
      pid = ServerManager.get_guild_node(msg.guild_id)
      :ok = ServerNode.dispatch_msg(pid, msg)
    end
  end

  def handle_event(_) do
    :ok
  end
end

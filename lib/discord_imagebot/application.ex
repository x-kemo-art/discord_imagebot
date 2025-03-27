defmodule DiscordImagebot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Scraper.Supervisor,
      DiscordImagebot.ServerManager,
      {Nostrum.Bot,
       %{
         name: DiscordImagebot,
         consumer: DiscordImagebot.Consumer,
         intents: [:message_content, :guild_messages],
         wrapped_token: fn ->
           System.fetch_env!("DC_TOKEN")
         end
       }}
    ]

    opts = [strategy: :one_for_one, name: DiscordImagebot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

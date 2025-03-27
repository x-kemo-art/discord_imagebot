defmodule Scraper.Supervisor do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    children = [
      Scraper.IconCache
    ]

    opts = [strategy: :one_for_one, name: Scraper.Supervisor]
    Supervisor.init(children, opts)
  end
end

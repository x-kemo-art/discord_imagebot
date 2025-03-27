defmodule Scraper.IconCache do
  use GenServer

  @unknown_icon_path "icons/unknown.svg"
  {:ok, bytes} = File.read(@unknown_icon_path)
  @unknown_icon_bytes bytes

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    :logger.debug("Starting icon cache @ #{inspect(self())}")

    :ets.new(
      __MODULE__,
      [:named_table, :public, write_concurrency: true]
    )

    {:ok, state}
  end

  defp load_icon(path) do
    result =
      case File.read(path) do
        {:ok, bytes} ->
          {bytes, Path.extname(path)}

        {:error, _} ->
          {@unknown_icon_bytes, ".svg"}
      end

    :ets.insert(__MODULE__, {path, result})

    result
  end

  def get_icon(path) do
    case :ets.lookup(__MODULE__, path) do
      [{^path, result}] -> result
      [] -> load_icon(path)
    end
  end
end

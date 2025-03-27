defmodule Scraper.Plugins.BinkyFish do
  alias Scraper.MastodonCompatible
  use Scraper.Plugin

  def name(), do: "Binkyfish"
  def footer_icon_path(), do: "icons/binkyfish.png"

  def url_matches?(url) do
    url.authority == "binky.fish"
  end

  def scrape(url) do
    MastodonCompatible.scrape(url, __MODULE__)
  end
end

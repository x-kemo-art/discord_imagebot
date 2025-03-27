defmodule Scraper.Plugins.Misskey do
  alias Scraper.MastodonCompatible
  use Scraper.Plugin

  def name(), do: "Misskey"
  def footer_icon_path(), do: ""

  def url_matches?(url) do
    String.contains?(url, "misskey.io")
  end

  def scrape(url) do
    MastodonCompatible.scrape(url, __MODULE__)
  end
end

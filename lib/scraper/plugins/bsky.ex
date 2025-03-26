defmodule Scraper.Plugins.Bsky do
  use Scraper.Plugin

  def name(), do: "Bluesky"

  def url_matches?(url) do
    url.authority == "bsky.app"
  end

  def scrape(_url) do
    {:ok, "scraped bsky"}
  end
end

defmodule Scraper.Plugins.Twitter do
  use Scraper.Plugin

  def name(), do: "Twitter"
  def footer_icon_path(), do: ""

  def url_matches?(url) do
    ["twitter.com", "x.com"]
    |> Enum.member?(url.authority)
  end

  def scrape(_url) do
    {:ok, "scraped twitter"}
  end
end

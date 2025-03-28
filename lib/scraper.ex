defmodule Scraper do
  @services [
    Scraper.Plugins.BinkyFish,
    Scraper.Plugins.Bsky,
    Scraper.Plugins.Misskey,
    Scraper.Plugins.Twitter
  ]

  def identify(url) do
    matched = match_url(url)

    case matched do
      {:match, module, url} -> {:ok, module, url}
      {:nomatch, _} -> {:error, :nomatch}
    end
  end

  def download(posts) do
    posts
    |> Enum.map(fn post ->
      files =
        post.files
        |> Stream.map(&post.plugin.download_file(&1))
        |> Enum.reject(
          &case &1 do
            {:error, _} -> true
            _ -> false
          end
        )

      %{post | files: files}
    end)
  end

  defp match_url(url) do
    url = URI.parse(url)
    match_url(url, @services)
  end

  defp match_url(result, [service | tail]) do
    match_url(
      service.__identify(result),
      tail
    )
  end

  defp match_url(result, []), do: result
end

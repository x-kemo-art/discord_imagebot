defmodule DiscordImagebot.Utils do
  @url_regex ~r"(http|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])"

  def extract_urls(text) do
    Regex.scan(@url_regex, text)
    |> Enum.map(&hd(&1))
  end
end

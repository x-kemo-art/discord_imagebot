defmodule Scraper.MastodonCompatible do
  def scrape(url, calling_module) do
    url_parsed = URI.parse(url)
    post_id = :lists.last(String.split(url_parsed.path, "/"))

    body =
      %{
        noteId: post_id
      }
      |> JSON.encode!()

    with {:ok, %{status_code: 200, body: data}} <-
           HTTPoison.post(
             "https://#{url_parsed.authority}/api/notes/show",
             body,
             [{"Content-Type", "application/json"}]
           ) do
      data = data |> JSON.decode!()

      post_text =
        case Map.get(data, "text") do
          nil -> "[Original post](#{url})"
          text -> text <> "\n\n[Original post](#{url})"
        end

      post_author_avatar_url = data["user"]["avatarUrl"]

      {
        post_author_username,
        post_author_display_name,
        post_author_url
      } =
        case data do
          %{"user" => %{"username" => username, "name" => display_name, "host" => nil}} ->
            {username, display_name, "https://#{url_parsed.authority}/@#{username}"}

          %{"user" => %{"username" => username, "name" => display_name, "host" => host}} ->
            {username, "#{display_name}@#{host}",
             "https://#{url_parsed.authority}/@#{username}@#{host}"}
        end

      post_files =
        data["files"]
        # strip queries
        |> Enum.map(&hd(String.split(&1["url"], "?")))

      {:ok, post_timestamp, _offset} =
        data["createdAt"]
        |> DateTime.from_iso8601()

      result = %Scraper.Post{
        username: post_author_username,
        display_name: post_author_display_name,
        author_url: post_author_url,
        avatar_url: post_author_avatar_url,
        text: post_text,
        files: post_files,
        timestamp: post_timestamp,
        post_url: URI.to_string(url),
        plugin: calling_module
      }

      {:ok, result}
    end
  end
end

defmodule DiscordImagebot.MessageTask do
  alias Scraper.Post
  alias Nostrum.Struct.Embed.Footer
  alias Nostrum.Struct.Embed.Author
  alias Nostrum.Struct.Embed
  alias DiscordImagebot.Utils
  alias Nostrum.Api.Message
  alias DiscordImagebot.ServerNode

  def start_link(msg) do
    spawn_link(__MODULE__, :run, [msg, self()])
  end

  def run(msg = %Nostrum.Struct.Message{}, caller) do
    posts =
      pull_valid_targets(msg.content)
      |> Scraper.download()
      |> Stream.map(&reformat_files(&1))
      |> Enum.map(&finish_post(&1))

    for post <- posts do
      IO.inspect(post)

      {:ok, _msg} =
        Message.create(msg.channel_id, %{
          embeds: [post.embed],
          files: post.files
        })
    end

    ServerNode.finish_embed_job(caller)
  end

  defp reformat_files(post = %Post{}) do
    files =
      post.files
      |> Enum.reduce(
        [],
        fn file, acc ->
          suffix = length(acc) |> Integer.to_string()
          {:ok, data, _mime_type, file_ext} = file

          [
            %{
              name: "attachment_#{suffix}#{file_ext}",
              body: data
            }
            | acc
          ]
        end
      )

    IO.inspect(files)
    %{post | files: files}
  end

  defp finish_post(post = %Post{}) do
    author_name =
      case {post.display_name, post.username} do
        {nil, nil} -> "unknown author"
        {nil, _} -> post.username
        {_, nil} -> post.display_name
        {_, _} -> "#{post.display_name} (#{post.username})"
      end

    {footer_icon_bytes, footer_icon_ext} = post.plugin.footer_icon()
    {:ok, avatar_bytes, _mime_type, avatar_ext} = post.plugin.download_file(post.avatar_url)

    embed = %Embed{
      author: %Author{
        name: author_name,
        url: post.author_url,
        icon_url: "attachment://avatar" <> avatar_ext
      },
      footer: %Footer{
        text: post.plugin.name(),
        icon_url: "attachment://footer" <> footer_icon_ext
      },
      description: post.text,
      timestamp: post.timestamp,
      title: Map.get(post, :title),
      url: post.post_url,
      color: 0xF8E45C
    }

    %{
      post
      | embed: embed,
        files: [
          %{
            name: "footer" <> footer_icon_ext,
            body: footer_icon_bytes
          },
          %{
            name: "avatar" <> avatar_ext,
            body: avatar_bytes
          }
          | post.files
        ]
    }
  end

  defp pull_valid_targets(msg_content) do
    Utils.extract_urls(msg_content)
    |> Stream.map(fn url ->
      case Scraper.identify(url) do
        {:error, _} -> nil
        {:ok, module, url} -> {module, url}
      end
    end)
    |> Stream.reject(&(&1 == nil))
    |> Stream.map(fn {module, url} ->
      case module.scrape(url) do
        {:ok, post} -> post
        {:error, _} -> nil
      end
    end)
    |> Enum.reject(&(&1 == nil))
  end
end

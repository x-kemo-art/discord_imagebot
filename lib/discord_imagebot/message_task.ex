defmodule DiscordImagebot.MessageTask do
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

    embeds = generate_embeds(posts)

    {:ok, _msg} =
      Message.create(msg.channel_id, %{
        content: "hello",
        embeds: embeds
      })

    ServerNode.finish_embed_job(caller)
  end

  defp generate_embeds(posts) do
    posts
    |> Enum.map(fn post ->
      author_name =
        case {post.display_name, post.username} do
          {nil, nil} -> "unknown author"
          {nil, _} -> post.username
          {_, nil} -> post.display_name
          {_, _} -> "#{post.display_name} (#{post.username})"
        end

      %Embed{
        author: %Author{
          name: author_name,
          url: post.author_url
        },
        footer: %Footer{
          text: post.plugin.name()
        },
        description: post.text,
        timestamp: post.timestamp,
        title: Map.get(post, :title),
        url: post.post_url,
        color: 0xF8E45C
      }
    end)
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

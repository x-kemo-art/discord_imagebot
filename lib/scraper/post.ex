defmodule Scraper.Post do
  @enforce_keys [
    :username,
    :display_name,
    :author_url,
    :avatar_url,
    :text,
    :files,
    :timestamp,
    :post_url,
    :plugin
  ]

  defstruct [
    :username,
    :display_name,
    :author_url,
    :avatar_url,
    :text,
    :files,
    :timestamp,
    :post_url,
    :embed,
    :plugin
  ]
end

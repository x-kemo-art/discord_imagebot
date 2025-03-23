defmodule DiscordImagebotTest do
  use ExUnit.Case
  doctest DiscordImagebot

  test "greets the world" do
    assert DiscordImagebot.hello() == :world
  end
end

defmodule Scraper.Plugin do
  @callback scrape(url :: binary) :: {:ok, contents :: term} | {:error, reason :: term}
  @callback url_matches?(url :: binary) :: result :: boolean
  @callback name() :: name :: binary

  def get_resp_file_info(resp) do
    with {:ok, mime_type} <- pull_mime_type_header(resp.headers),
         :ok <- verify_image_type(mime_type) do
      case MIME.extensions(mime_type) do
        [file_ext | _] -> {:ok, mime_type, file_ext}
        [] -> {:error, "no file extension"}
      end
    end
  end

  defp pull_mime_type_header(headers) do
    content_type =
      headers
      |> Enum.find(
        &case &1 do
          {"Content-Type", _type} -> true
          {"content-type", _type} -> true
          _ -> false
        end
      )

    case content_type do
      {"Content-Type", type} -> {:ok, type}
      _ -> {:error, "no content type"}
    end
  end

  defp verify_image_type(mime_type) do
    case hd(String.split(mime_type, "/")) do
      "image" -> :ok
      _ -> {:error, "MIME-type is not an image"}
    end
  end

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour Scraper.Plugin

      def __identify(result = {:nomatch, url}) do
        if url_matches?(url) do
          {:match, __MODULE__, url}
        else
          {:nomatch, url}
        end
      end

      def __identify(result = {:match, _module, _url}), do: result

      def __identify(url), do: __identify({:nomatch, url})

      def download_file(url) do
        with {:ok, resp = %{status_code: 200, body: img_data}} <- HTTPoison.get(url),
             {:ok, mime_type, file_ext} <- Scraper.Plugin.get_resp_file_info(resp) do
          {:ok, img_data, mime_type, file_ext}
        end
      end

      defoverridable download_file: 1
    end
  end
end

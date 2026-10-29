defmodule Tldr.OpenRouter do
  @moduledoc """
  The one call to OpenRouter's chat completions API.

  It asks for JSON that matches a schema and returns the decoded object.
  """

  @endpoint "https://openrouter.ai/api/v1/chat/completions"

  @doc """
  Sends `body` (messages, model, provider and so on) and returns the
  decoded JSON answer of the model.
  """
  @spec complete(map()) :: {:ok, map()} | {:error, term()}
  def complete(body) do
    options =
      [
        url: @endpoint,
        json: body,
        auth: {:bearer, api_key()},
        headers: [x_title: "tldr"],
        # A long video takes the model a while to watch.
        receive_timeout: 300_000
      ] ++ Application.get_env(:tldr, __MODULE__, [])

    case Req.post(options) do
      {:ok, %Req.Response{status: 200, body: %{"choices" => [%{"message" => message} | _]}}} ->
        decode(message["content"])

      {:ok, %Req.Response{body: %{"error" => %{"message" => message}}}} ->
        {:error, {:openrouter, message}}

      {:ok, %Req.Response{status: status}} ->
        {:error, {:http_status, status}}

      {:error, exception} ->
        {:error, {:unreachable, Exception.message(exception)}}
    end
  end

  defp decode(content) when is_binary(content) do
    case Jason.decode(content) do
      {:ok, %{} = object} -> {:ok, object}
      _ -> {:error, :invalid_answer}
    end
  end

  defp decode(_content), do: {:error, :invalid_answer}

  defp api_key do
    Application.get_env(:tldr, :openrouter_api_key) ||
      raise "OPENROUTER_API_KEY is missing. Put it into .env or the environment."
  end
end

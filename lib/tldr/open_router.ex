defmodule Tldr.OpenRouter do
  @moduledoc """
  The one call to OpenRouter's chat completions API.

  It asks for JSON that matches a schema and validates the decoded summary.
  Every failure of the call itself is `{:openrouter, message}`, so it is
  never mistaken for a failure of the page.
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
        receive_timeout: 300_000,
        # A pooled connection the server already closed fails at once with
        # "socket closed". Req retries only GET by default; this POST is
        # retried on such transport errors, 408, 429 and 5xx.
        retry: :transient,
        max_retries: 2
      ] ++ Application.get_env(:tldr, __MODULE__, [])

    case Req.post(options) do
      {:ok, %Req.Response{status: 200, body: %{"choices" => [%{"message" => message} | _]}}} ->
        decode(message["content"])

      {:ok, %Req.Response{body: %{"error" => %{"message" => message}}}} ->
        {:error, {:openrouter, message}}

      {:ok, %Req.Response{status: status}} ->
        {:error, {:openrouter, "HTTP #{status}"}}

      {:error, exception} ->
        {:error, {:openrouter, Exception.message(exception)}}
    end
  end

  defp decode(content) when is_binary(content) do
    case Jason.decode(content) do
      {:ok, object} -> validate(object)
      _ -> {:error, :invalid_answer}
    end
  end

  defp decode(_content), do: {:error, :invalid_answer}

  # Character limits allow normal prose in both languages without enforcing word counts.
  defp validate(%{"tldr" => tldr, "points" => points} = answer)
       when map_size(answer) == 2 and is_list(points) and length(points) <= 6 do
    if short_text?(tldr, 500) and Enum.all?(points, &short_text?(&1, 400)),
      do: {:ok, answer},
      else: {:error, :invalid_answer}
  end

  defp validate(_answer), do: {:error, :invalid_answer}

  defp short_text?(text, limit) when is_binary(text),
    do: String.length(text) <= limit and String.trim(text) != ""

  defp short_text?(_text, _limit), do: false

  defp api_key do
    Application.get_env(:tldr, :openrouter_api_key) ||
      raise "OPENROUTER_API_KEY is missing. Put it into .env or the environment."
  end
end

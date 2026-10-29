defmodule Tldr.Summary do
  @moduledoc "What a summarized address comes back as."

  defstruct [:url, :kind, :title, :channel, :tldr, points: []]

  @type t :: %__MODULE__{
          url: String.t(),
          kind: :web | :youtube,
          title: String.t() | nil,
          channel: String.t() | nil,
          tldr: String.t(),
          points: [String.t()]
        }
end

defmodule Tldr.Repo do
  @moduledoc "The Postgres database. It holds only the cache (`Tldr.Cache`)."

  use Ecto.Repo, otp_app: :tldr, adapter: Ecto.Adapters.Postgres
end

defmodule Tldr.Repo.Migrations.CreateSummaries do
  use Ecto.Migration

  # One finished summary per address and language (`Tldr.Cache`).
  def change do
    create table(:summaries, primary_key: false) do
      add :url, :text, primary_key: true
      add :language, :text, primary_key: true
      add :kind, :text, null: false
      add :title, :text
      add :channel, :text
      add :tldr, :text, null: false
      add :points, {:array, :text}, null: false
      add :saved_at, :timestamptz, null: false
    end

    create index(:summaries, [:saved_at])
  end
end

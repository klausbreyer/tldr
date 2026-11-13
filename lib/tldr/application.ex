defmodule Tldr.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TldrWeb.Telemetry,
      Tldr.Repo,
      # A release migrates the database when it starts; dev and test use mix.
      {Ecto.Migrator, repos: [Tldr.Repo], skip: System.get_env("RELEASE_NAME") == nil},
      {DNSCluster, query: Application.get_env(:tldr, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Tldr.PubSub},
      # Summaries that outlive their page (`Tldr.Job`), one per address.
      {Registry, keys: :unique, name: Tldr.Job.Registry},
      {DynamicSupervisor, name: Tldr.Job.Supervisor},
      # Start to serve requests, typically the last entry
      TldrWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Tldr.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TldrWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

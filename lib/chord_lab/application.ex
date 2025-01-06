defmodule ChordLab.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ChordLabWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:chord_lab, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ChordLab.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: ChordLab.Finch},
      {Redix, {Application.fetch_env!(:redix, :url), name: :chord_redis}},
      ChordLabWeb.Presence,
      {Registry, keys: :unique, name: ChordLab.Registry},
      # Start a worker by calling: ChordLab.Worker.start_link(arg)
      # {ChordLab.Worker, arg},
      # Start to serve requests, typically the last entry
      ChordLabWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ChordLab.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ChordLabWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

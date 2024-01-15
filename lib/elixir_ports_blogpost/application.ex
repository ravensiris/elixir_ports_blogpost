defmodule ElixirPortsBlogpost.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ElixirPortsBlogpostWeb.Telemetry,
      ElixirPortsBlogpost.Repo,
      {DNSCluster, query: Application.get_env(:elixir_ports_blogpost, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ElixirPortsBlogpost.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: ElixirPortsBlogpost.Finch},
      # Start a worker by calling: ElixirPortsBlogpost.Worker.start_link(arg)
      # {ElixirPortsBlogpost.Worker, arg},
      # Start to serve requests, typically the last entry
      ElixirPortsBlogpostWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixirPortsBlogpost.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ElixirPortsBlogpostWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

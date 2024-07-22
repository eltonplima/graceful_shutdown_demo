defmodule GracefulShutdownDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies, [])

    children = [
      {Cluster.Supervisor, [topologies]},
      GracefulShutdownDemoWeb.Telemetry,
      GracefulShutdownDemo.Repo,
      {DNSCluster,
       query: Application.get_env(:graceful_shutdown_demo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GracefulShutdownDemo.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: GracefulShutdownDemo.Finch},
      # Start a worker by calling: GracefulShutdownDemo.Worker.start_link(arg)
      # {GracefulShutdownDemo.Worker, arg},
      # Start to serve requests, typically the last entry
      GracefulShutdownDemoWeb.Endpoint,
      GracefulShutdownDemo.Foo,
      GracefulShutdownDemo.Bar
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GracefulShutdownDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GracefulShutdownDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

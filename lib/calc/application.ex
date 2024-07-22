defmodule Calc.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CalcWeb.Telemetry,
      Calc.Repo,
      {DNSCluster,
       query: Application.get_env(:calc, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Calc.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Calc.Finch},
      # Start a worker by calling: Calc.Worker.start_link(arg)
      # {Calc.Worker, arg},
      # Start to serve requests, typically the last entry
      CalcWeb.Endpoint,
      Calc.Foo,
      Calc.Bar
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Calc.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CalcWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

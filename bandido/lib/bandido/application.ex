defmodule Bandido.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BandidoWeb.Telemetry,
      Bandido.Repo,
      {DNSCluster, query: Application.get_env(:bandido, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Bandido.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Bandido.Finch},
      # Conditional start for Crawly.Engine
      # Start to serve requests, typically the last entry
      BandidoWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bandido.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BandidoWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp crawly_engine_child_spec do
    case Process.whereis(Crawly.Engine) do
      nil ->
        {Crawly.Engine, []}
      pid when is_pid(pid) ->
        # Crawly.Engine is already started, return a no-op child spec
        %{id: Crawly.Engine, start: {:ignore, :already_started}, type: :supervisor}
    end
  end
end

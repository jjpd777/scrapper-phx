defmodule BandidoWeb.TriggerLive do
  use BandidoWeb, :live_view
  alias Bandido.SpiderMan
  alias Bandido.CrawlyChecker
  require Logger

  def mount(_params, _session, socket) do
    Logger.info("TriggerLive mount called")
    if connected?(socket) do
      Logger.info("TriggerLive connected, subscribing to spider_results")
      Phoenix.PubSub.subscribe(Bandido.PubSub, "spider_results")
    end
    {:ok, assign(socket, html_content: nil, error: nil, spider_running: false)}
  end

  def handle_event("start_spider", _params, %{assigns: %{spider_running: true}} = socket) do
    {:noreply, put_flash(socket, :info, "Spider is already running")}
  end

  def handle_event("start_spider", _params, socket) do
    Logger.info("TriggerLive start_spider event received")
    Task.start(fn ->
      try do
        Logger.info("Starting SpiderMan spider")
        case Crawly.Engine.start_spider(SpiderMan) do
          :ok ->
            Logger.info("Spider started successfully")
            Phoenix.PubSub.broadcast(Bandido.PubSub, "spider_results", {:spider_status, :running})
          {:error, :spider_already_started} ->
            Logger.info("Spider is already running")
            Phoenix.PubSub.broadcast(Bandido.PubSub, "spider_results", {:spider_status, :running})
          {:error, reason} ->
            Logger.error("Failed to start spider: #{inspect(reason)}")
            Phoenix.PubSub.broadcast(Bandido.PubSub, "spider_results", {:spider_error, "Failed to start spider: #{inspect(reason)}"})
        end
      rescue
        e ->
          Logger.error("Error starting spider: #{inspect(e)}")
          Phoenix.PubSub.broadcast(Bandido.PubSub, "spider_results", {:spider_error, "Error starting spider: #{inspect(e)}"})
      end
    end)
    {:noreply, put_flash(socket, :info, "Spider start initiated")}
  end

  def handle_event("stop_spider", _params, socket) do
    Logger.info("TriggerLive stop_spider event received")
    case Crawly.Engine.stop_spider(SpiderMan) do
      :ok ->
        Logger.info("Spider stopped successfully")
        Phoenix.PubSub.broadcast(Bandido.PubSub, "spider_results", {:spider_status, :stopped})
        {:noreply, put_flash(socket, :info, "Spider stopped")}
      {:error, reason} ->
        Logger.error("Failed to stop spider: #{inspect(reason)}")
        {:noreply, put_flash(socket, :error, "Failed to stop spider: #{inspect(reason)}")}
    end
  end

  def handle_info({:spider_results, html_content}, socket) do
    Logger.info("TriggerLive received spider results")
    {:noreply, assign(socket, html_content: html_content, error: nil)}
  end

  def handle_info({:spider_error, error_message}, socket) do
    Logger.error("TriggerLive received spider error: #{error_message}")
    {:noreply, assign(socket, error: error_message, spider_running: false)}
  end

  def handle_info({:spider_status, status}, socket) do
    Logger.info("TriggerLive received spider status: #{status}")
    {:noreply, assign(socket, spider_running: status == :running)}
  end

  def handle_event("check_crawly", _params, socket) do
    Logger.info("Running Crawly configuration checks")
    CrawlyChecker.run_checks()
    {:noreply, put_flash(socket, :info, "Crawly checks completed. Check server logs for details.")}
  end

  def render(assigns) do
    Logger.info("TriggerLive render called")
    ~H"""
    <div>
      <h1>Trigger Spider</h1>
      <%= if @spider_running do %>
        <button phx-click="stop_spider">Stop Spider</button>
      <% else %>
        <button phx-click="start_spider">Start Spider</button>
      <% end %>
      <button phx-click="check_crawly">Check Crawly Configuration</button>
      <%= if flash = live_flash(@flash, :info) do %>
        <p class="alert alert-info"><%= flash %></p>
      <% end %>
      <%= if @error do %>
        <p class="alert alert-danger"><%= @error %></p>
      <% end %>
      <%= if @html_content do %>
        <h2>Fetched HTML Content:</h2>
        <pre><code><%= raw @html_content %></code></pre>
      <% end %>
    </div>
    """
  end
end

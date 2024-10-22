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
    {:ok, assign(socket, results: [], error: nil)}
  end

  def handle_event("start_spider", _params, socket) do
    Logger.info("TriggerLive start_spider event received")
    Task.start(fn ->
      try do
        Logger.info("Starting SpiderMan spider")
        case Crawly.Engine.start_spider(SpiderMan) do
          :ok ->
            Logger.info("Spider started successfully")
            Process.sleep(30_000)  # Wait for 30 seconds
            Logger.info("Fetching results from SpiderMan")
            results = Crawly.fetch(SpiderMan)
            Logger.info("Spider results: #{inspect(results)}")
            Phoenix.PubSub.broadcast(Bandido.PubSub, "spider_results", {:spider_results, results})
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

  def handle_info({:spider_results, results}, socket) do
    Logger.info("TriggerLive received spider results")
    {:noreply, assign(socket, results: results, error: nil)}
  end

  def handle_info({:spider_error, error_message}, socket) do
    Logger.error("TriggerLive received spider error: #{error_message}")
    {:noreply, assign(socket, error: error_message)}
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
      <button phx-click="start_spider">Start Spider</button>
      <button phx-click="check_crawly">Check Crawly Configuration</button>
      <%= if flash = live_flash(@flash, :info) do %>
        <p class="alert alert-info"><%= flash %></p>
      <% end %>
      <%= if @error do %>
        <p class="alert alert-danger"><%= @error %></p>
      <% end %>
      <h2>Results:</h2>
      <ul>
        <%= for result <- @results do %>
          <li><%= inspect(result) %></li>
        <% end %>
      </ul>
    </div>
    """
  end
end

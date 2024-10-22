 # lib/crawly_example/books_to_scrape.ex
 defmodule Bandido.SpiderMan do
  use Crawly.Spider
  require Logger

  @impl Crawly.Spider
  def base_url, do: "https://www.chatgpt.com/"

  @impl Crawly.Spider
  def init do
    Logger.info("SpiderMan init called")
    [start_urls: ["https://chatgpt.com/share/67170dbc-bc10-8004-9d9e-a923616a5aba/"]]
  end

  @impl Crawly.Spider
  def parse_item(response) do
    Logger.info("SpiderMan parse_item called for URL: #{response.request_url}")

    # Broadcast the HTML content
    Phoenix.PubSub.broadcast(Bandido.PubSub, "spider_results", {:spider_results, response.body})

    # Return an empty ParsedItem to prevent further crawling
    %Crawly.ParsedItem{items: [], requests: []}
  end
end

 # lib/crawly_example/books_to_scrape.ex
 defmodule Bandido.SpiderMan do
  use Crawly.Spider
  import Floki
  require Logger

  @impl Crawly.Spider
  def base_url, do: "https://books.toscrape.com/"

  @impl Crawly.Spider
  def init do
    Logger.info("SpiderMan init called")
    [start_urls: ["https://books.toscrape.com/"]]
  end

  @impl Crawly.Spider
  def parse_item(response) do
    Logger.info("SpiderMan parse_item called for URL: #{response.request_url}")

    # Parse response body to document
    {:ok, document} = Floki.parse_document(response.body)

    # Create item (for pages where items exists)
    items =
      document
      |> Floki.find(".product_pod")
      |> Enum.map(fn x ->
        item = %{
          title: Floki.find(x, "h3 a") |> Floki.attribute("title") |> Floki.text(),
          price: Floki.find(x, ".product_price .price_color") |> Floki.text(),
          url: response.request_url
        }
        Logger.info("Scraped item: #{inspect(item)}")
        item
      end)

    next_requests =
      document
      |> Floki.find(".next a")
      |> Floki.attribute("href")
      |> Enum.map(fn url ->
        Crawly.Utils.build_absolute_url(url, response.request.url)
        |> Crawly.Utils.request_from_url()
      end)

    Logger.info("SpiderMan parse_item finished. Items: #{length(items)}, Next requests: #{length(next_requests)}")
    %Crawly.ParsedItem{items: items, requests: next_requests}
  end
end

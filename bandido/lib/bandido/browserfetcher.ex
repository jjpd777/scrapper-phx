defmodule Bandido.BrowserFetcher do
  require Logger

  @moduledoc """
  A module for fetching web pages using a headless browser.
  """

  def fetch(request, _client_options) do
    Logger.info("Starting fetch for URL: #{request.url}")

    try do
      {:ok, session} = Wallaby.start_session(
        capabilities: %{
          javascriptEnabled: false,
          chromeOptions: %{args: [""]}
        }
      )
      Logger.info("Session started successfully with ID: #{inspect(session.id)}")

      result = process_with_session(session, request)

      Wallaby.end_session(session)

      result
    rescue
      e ->
        Logger.error("Error during fetch: #{inspect(e)}")
        {:error, %HTTPoison.Error{reason: e}}
    end
  end

  defp process_with_session(session, request) do
    try do
      Logger.info("Attempting to visit URL: #{request.url}")

      {:ok, visit_result} = Wallaby.Browser.visit(session, request.url)
      Logger.info("URL visited successfully. Visit result: #{inspect(visit_result)}")

      body = Wallaby.Browser.page_source(session)
      Logger.info("Page source fetched, length: #{String.length(body)}")

      url = Wallaby.Browser.current_url(session)
      Logger.info("Current URL after fetch: #{url}")

      {:ok, %HTTPoison.Response{status_code: 200, body: body, request_url: url}}
    rescue
      e ->
        Logger.error("Error during fetch: #{inspect(e)}")
        {:error, %HTTPoison.Error{reason: e}}
    after
      Logger.info("Ending session with ID: #{session.id}")
      Wallaby.end_session(session)
    end
  end
end

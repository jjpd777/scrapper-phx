defmodule Bandido.CrawlyChecker do
  require Logger

  def run_checks do
    Logger.info("Running Crawly configuration checks...")

    check_application_started()
    check_engine_process()
    check_configuration()
    check_spider_module()

    Logger.info("Crawly configuration checks completed.")
  end

  defp check_application_started do
    case Application.started_applications() |> Enum.find(fn {app, _, _} -> app == :crawly end) do
      nil ->
        Logger.error("Crawly application is not started!")
      {_, _, version} ->
        Logger.info("Crawly application is started. Version: #{version}")
    end
  end

  defp check_engine_process do
    case Process.whereis(Crawly.Engine) do
      nil ->
        Logger.error("Crawly.Engine process is not running!")
      pid ->
        Logger.info("Crawly.Engine process is running. PID: #{inspect(pid)}")
    end
  end

  defp check_configuration do
    config = Application.get_all_env(:crawly)
    Logger.info("Crawly configuration: #{inspect(config, pretty: true)}")

    # Check specific important configurations
    check_config_value(config, :closespider_timeout)
    check_config_value(config, :concurrent_requests_per_domain)
    check_config_value(config, :closespider_itemcount)
    check_config_value(config, :fetcher)
    check_config_value(config, :parser)
  end

  defp check_config_value(config, key) do
    case Keyword.get(config, key) do
      nil ->
        Logger.warn("Configuration for :#{key} is not set.")
      value ->
        Logger.info("Configuration for :#{key} is set to: #{inspect(value)}")
    end
  end

  defp check_spider_module do
    case Code.ensure_loaded(Bandido.SpiderMan) do
      {:module, _} ->
        Logger.info("SpiderMan module is loaded.")
        check_spider_callbacks()
      {:error, reason} ->
        Logger.error("Failed to load SpiderMan module. Reason: #{inspect(reason)}")
    end
  end

  defp check_spider_callbacks do
    callbacks = [
      :base_url,
      :init,
      :parse_item
    ]

    Enum.each(callbacks, fn callback ->
      if function_exported?(Bandido.SpiderMan, callback, 0) or function_exported?(Bandido.SpiderMan, callback, 1) do
        Logger.info("SpiderMan implements #{callback} callback.")
      else
        Logger.warn("SpiderMan does not implement #{callback} callback!")
      end
    end)
  end
end

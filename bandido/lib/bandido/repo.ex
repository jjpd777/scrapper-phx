defmodule Bandido.Repo do
  use Ecto.Repo,
    otp_app: :bandido,
    adapter: Ecto.Adapters.Postgres
end

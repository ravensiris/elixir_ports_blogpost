defmodule ElixirPortsBlogpost.Repo do
  use Ecto.Repo,
    otp_app: :elixir_ports_blogpost,
    adapter: Ecto.Adapters.Postgres
end

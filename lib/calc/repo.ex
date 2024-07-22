defmodule Calc.Repo do
  use Ecto.Repo,
    otp_app: :calc,
    adapter: Ecto.Adapters.Postgres
end

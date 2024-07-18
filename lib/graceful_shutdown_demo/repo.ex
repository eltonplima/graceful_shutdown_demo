defmodule GracefulShutdownDemo.Repo do
  use Ecto.Repo,
    otp_app: :graceful_shutdown_demo,
    adapter: Ecto.Adapters.Postgres
end

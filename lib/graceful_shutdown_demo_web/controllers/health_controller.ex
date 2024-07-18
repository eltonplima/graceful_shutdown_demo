defmodule GracefulShutdownDemoWeb.HealthController do
  use GracefulShutdownDemoWeb, :controller

  action_fallback(GracefulShutdownDemoWeb.FallbackController)

  def health(conn, _params) do
    json(conn, %{status: "ok"})
  end
end

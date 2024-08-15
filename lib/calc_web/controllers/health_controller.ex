defmodule CalcWeb.HealthController do
  use CalcWeb, :controller

  action_fallback(CalcWeb.FallbackController)

  def health(conn, _params) do
    json(conn, %{status: "ok"})
  end
end

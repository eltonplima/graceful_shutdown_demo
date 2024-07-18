defmodule GracefulShutdownDemoWeb.SlowMathController do
  use GracefulShutdownDemoWeb, :controller

  action_fallback(GracefulShutdownDemoWeb.FallbackController)

  def sum(conn, %{"version" => version, "numbers" => numbers}) do
    with {:ok, result} <- slow_sum(version, numbers) do
      json(conn, %{result: result})
    end
  end

  defp slow_sum("1", numbers) do
    Process.sleep(100)
    Enum.sum(numbers)
  end

  defp slow_sum(_, _), do: {:error, :unsupported_version}
end

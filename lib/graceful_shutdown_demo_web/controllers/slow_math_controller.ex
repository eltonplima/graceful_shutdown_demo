defmodule GracefulShutdownDemoWeb.SlowMathController do
  use GracefulShutdownDemoWeb, :controller

  def sum(conn, %{"version" => version, "numbers" => numbers}) do
   json(conn, %{result: slow_sum(version, numbers)})
  end

  defp slow_sum("1", numbers) do
    Process.sleep(100)
    Enum.sum(numbers)
  end

  defp slow_sum(_, _), do: {:error, "Unsupported version"}
end

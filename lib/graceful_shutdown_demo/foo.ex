defmodule GracefulShutdownDemo.Foo do
  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init([]) do
    Process.flag(:trap_exit, true)
    Logger.info("Foo starting...")
    {:ok, nil}
  end

  @impl true
  def terminate(reason, _state) do
    Logger.info("Foo terminating with reason: #{inspect(reason)}")
    Process.sleep(2000)
    Logger.info("Foo terminated")
  end
end

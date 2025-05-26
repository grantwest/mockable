defmodule MockableProdTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  test "prod only defines original module" do
    Application.put_env(:mockable, Client, ClientAlt)
    Mockable.use(Client, ClientAlt)
    # runtime diretives to use ClientAlt have no effect
    assert Client.mockable_function("d") == "d prod"
  end

  test "does not log which module is being used" do
    {result, log} = with_log(fn -> Client.mockable_function("a") end)
    assert result == "a prod"
    assert log == ""
  end
end

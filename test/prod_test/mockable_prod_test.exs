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

  test "stacktrace is normal" do
    try do
      Client.raises()
    rescue
      e in RuntimeError ->
        assert e.message == "prod raises"

        assert [
                 {Client, :raises, 0,
                  [
                    file: ~c"test/support/client.ex",
                    line: 60,
                    error_info: %{module: Exception}
                  ]}
                 | _rest
               ] = __STACKTRACE__
    end
  end
end

defmodule MockableTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog
  import Mox

  doctest Mockable
  setup :verify_on_exit!

  test "use configured mox by default" do
    # because the Mox is configured in config/test.exs
    expect(Client.Mock, :mockable_function, fn "a" -> "mox" end)
    assert Client.mockable_function("a") == "mox"
  end

  test "implementation configured in process memory overrides config" do
    Mockable.use(Client, ClientAlt)
    assert Client.mockable_function("a") == "a alt"
  end

  test "can override config at runtime" do
    Application.put_env(:mockable, Client, ClientAlt)
    assert Client.mockable_function("b") == "b alt"
    Application.put_env(:mockable, Client, Client.Mock)
  end

  test "use/1 overrides config and uses the original module" do
    Mockable.use(Client)
    assert Client.mockable_function("c") == "c prod"
  end

  test "logs which modules is being used" do
    Mockable.use(Client, ClientAlt)
    {result, log} = with_log(fn -> Client.log_test_function("l") end)
    assert result == "l alt output"
    assert log =~ "Using ClientAlt.log_test_function/1 for Client"
  end

  test "does not override functions that are not callbacks" do
    assert Client.not_a_callback() == "prod"
    Mockable.use(Client, ClientAlt)
    assert Client.not_a_callback() == "prod"
  end

  test "does not override functions that have different arity than callbacks" do
    Mockable.use(Client, ClientAlt)
    assert Client.arity_specific() == "alt"
    assert Client.arity_specific(1) == "prod"
  end
end

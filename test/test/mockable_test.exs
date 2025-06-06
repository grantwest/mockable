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

  @tag :dialyzer
  test "dialyzer detects type violations in mockable functions, using callbacks as spec" do
    dialyzer_args = [
      check_plt: false,
      init_plt: String.to_charlist(Dialyxir.Project.plt_file()),
      files: Dialyxir.Project.dialyzer_files(),
      warnings: [:unknown]
    ]

    client_warnings =
      :dialyzer.run(dialyzer_args)
      |> Enum.filter(fn {_tag, {file, _location}, _warning} ->
        String.ends_with?(List.to_string(file), "test/support/client.ex")
      end)

    function_lines = function_lines(Client)
    argument_fail_line = function_lines.dialyzer_argument_fail + 1
    return_fail_line = function_lines.dialyzer_return_fail + 1

    assert [
             {:warn_failing_call, {~c"test/support/client.ex", {_line, _col}},
              {:call,
               [
                 Client,
                 :spec_tester,
                 ~c"('not_a_string')",
                 [1],
                 :only_contract,
                 ~c"(any())",
                 ~c"any()",
                 {true, ~c"('Elixir.String':t()) -> 'Elixir.String':t()"}
               ]}}
           ] = warning_for_line(client_warnings, argument_fail_line)

    assert [
             {:warn_failing_call, {~c"test/support/client.ex", {_line, _col}},
              {:call,
               [
                 :erlang,
                 :+,
                 ~c"(binary(),1)",
                 [1],
                 :only_sig,
                 ~c"(number(),number())",
                 ~c"number()",
                 {false, :none}
               ]}}
           ] = warning_for_line(client_warnings, return_fail_line)
  end

  defp warning_for_line(warnings, line_number) do
    warnings
    |> Enum.filter(fn
      {_type, {_path, {line, _col}}, _warning} ->
        line == line_number

      {_type, {_path, line}, _warning} ->
        line == line_number
    end)
  end

  defp function_lines(module) do
    module.module_info(:compile)[:source]
    |> File.read!()
    |> Code.string_to_quoted!(line: 1)
    |> extract_function_lines([])
    |> Enum.into(%{})
  end

  # Helper function to extract function line numbers from AST
  defp extract_function_lines({:defmodule, _meta, [_module_name, [do: body]]}, acc) do
    extract_function_lines(body, acc)
  end

  defp extract_function_lines({:__block__, _meta, statements}, acc) do
    Enum.reduce(statements, acc, &extract_function_lines/2)
  end

  defp extract_function_lines({:def, meta, [{function_name, _meta2, _args} | _body]}, acc)
       when is_atom(function_name) do
    line = meta[:line]
    [{function_name, line} | acc]
  end

  defp extract_function_lines(_other, acc), do: acc
end

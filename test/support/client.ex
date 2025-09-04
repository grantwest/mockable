defmodule Client do
  use Mockable

  # define a type used in the @callback as an example of a realistic use case
  @type custom_string() :: String.t()

  @callback mockable_function(String.t()) :: String.t()
  @callback log_test_function(String.t()) :: String.t()
  @callback arity_specific() :: String.t()
  @callback guarded_function(atom() | integer()) :: String.t()
  @callback pattern_matched_function(map() | list()) :: String.t()
  @callback spec_tester(String.t()) :: String.t()
  @callback raises() :: custom_string()

  @impl true
  def mockable_function(request) do
    # validate that private function is available
    defp_func()
    "#{request} prod"
  end

  # define dedicated function for log test to avoid log pollution
  @impl true
  def log_test_function(input) do
    "#{input} prod output"
  end

  @impl true
  def arity_specific(), do: "prod"

  def arity_specific(i), do: "prod #{i}"

  def not_a_callback(), do: "prod"

  @impl true
  def guarded_function(atom) when is_atom(atom) do
    "prod atom = #{atom}"
  end

  def guarded_function(integer) when is_integer(integer) do
    "prod integer = #{integer}"
  end

  @impl true
  def pattern_matched_function(%{key: value}) do
    "prod map with key = #{value}"
  end

  def pattern_matched_function([head | _tail]) do
    "prod list with head = #{head}"
  end

  @impl true
  def spec_tester(input) do
    input
  end

  @impl true
  def raises() do
    raise "prod raises"
  end

  def dialyzer_argument_ok() do
    spec_tester("string")
  end

  def dialyzer_argument_fail() do
    spec_tester(:not_a_string)
  end

  def dialyzer_return_ok() do
    spec_tester("string") |> String.trim()
  end

  def dialyzer_return_fail() do
    spec_tester("string") + 1
  end

  # to make test more complete
  # to prevent regression of macro failing on private functions
  defp defp_func() do
    :nothing
  end

  # just to use private function to avoid warning
  def def_func() do
    defp_func()
  end
end

defmodule ClientAlt do
  @behaviour Client

  @impl true
  def mockable_function(request) do
    "#{request} alt"
  end

  @impl true
  def log_test_function(input) do
    "#{input} alt output"
  end

  @impl true
  def arity_specific(), do: "alt"

  def arity_specific(i), do: "alt #{i}"

  def not_a_callback(), do: "alt"

  @impl true
  def guarded_function(atom) when is_atom(atom) do
    "alt atom = #{atom}"
  end

  def guarded_function(integer) when is_integer(integer) do
    "alt integer = #{integer}"
  end

  @impl true
  def pattern_matched_function(%{key: value}) do
    "alt map with key = #{value}"
  end

  def pattern_matched_function([head | _tail]) do
    "alt list with head = #{head}"
  end

  @impl true
  def spec_tester(input) do
    input
  end

  @impl true
  def raises() do
    raise "alt raises"
  end

  # to make test more complete
  # to prevent regression of macro failing on private functions
  defp defp_func() do
    :nothing
  end

  # just to use private function to avoid warning
  def def_func() do
    defp_func()
  end
end

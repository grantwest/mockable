defmodule Client do
  use Mockable

  @callback mockable_function(String.t()) :: String.t()
  @callback log_test_function(String.t()) :: String.t()
  @callback arity_specific() :: String.t()
  @callback spec_tester(String.t()) :: String.t()

  @impl true
  def mockable_function(request) do
    "#{request} prod"
  end

  # define dedicated function for log test to avoid log pollution
  @impl true
  def log_test_function(input) do
    "#{input} prod output"
  end

  @impl true
  def arity_specific(), do: "prod"

  def arity_specific(_i), do: "prod"

  def not_a_callback(), do: "prod"

  @impl true
  def spec_tester(input) do
    input
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
  def spec_tester(input) do
    input
  end
end

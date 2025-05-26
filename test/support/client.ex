defmodule Client do
  use Mockable

  @callback mockable_function(String.t()) :: String.t()
  @callback log_test_function(String.t()) :: String.t()
  @callback arity_specific() :: String.t()

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
end

defmodule ClientAlt do
  @behaviour Client

  @impl Client
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
end

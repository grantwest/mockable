defmodule Mockable do
  @moduledoc """
  Documentation for `Mockable`.
  """

  @doc """
  Configures which module to use for a given mockable module.
  If no implementation is provided, the mockable module itself will be used.

  This is useful for testing your Mockable module.

  ```elixir
  Mockable.use(Client)
  ```

  Or to use a specific implementation:
  ```elixir
  Mockable.use(Client, ClientMock)
  ```

  This function stores the configuration in process memory so that it is compatible with async tests.
  """
  def use(mockable, implementation \\ nil) do
    implementation = implementation || mockable
    Process.put({Mockable, mockable}, implementation)
  end

  defmacro __using__(_opts) do
    quote do
      @before_compile unquote(__MODULE__)
      @behaviour __MODULE__
    end
  end

  defmacro __before_compile__(env) do
    module = env.module
    module_string = module |> Atom.to_string() |> String.replace_prefix("Elixir.", "")

    if Application.get_all_env(:mockable) != [] do
      callbacks =
        Module.get_attribute(module, :callback)
        |> Enum.map(fn {:callback, {:"::", _, [{name, _, args} | _]}, _} ->
          {name, length(args)}
        end)

      functions =
        Module.definitions_in(module, :def)
        |> Enum.filter(&(&1 in callbacks))

      wrapped_functions =
        for {name, arity} <- functions do
          args = Macro.generate_arguments(arity, __MODULE__)

          quote do
            defoverridable [{unquote(name), unquote(arity)}]

            def unquote(name)(unquote_splicing(args)) do
              implementation =
                Process.get({Mockable, unquote(module)}) ||
                  Application.get_env(:mockable, unquote(module))

              log? = Application.get_env(:mockable, :log, true)

              if implementation != unquote(module) do
                log? &&
                  Logger.debug(
                    "Using #{inspect(implementation)}.#{unquote(name)}/#{unquote(arity)} for #{unquote(module_string)}"
                  )

                apply(implementation, unquote(name), [unquote_splicing(args)])
              else
                log? &&
                  Logger.debug(
                    "Using #{inspect(unquote(module))}.#{unquote(name)}/#{unquote(arity)} for #{unquote(module_string)}"
                  )

                super(unquote_splicing(args))
              end
            end
          end
        end

      quote do
        require Logger
        (unquote_splicing(wrapped_functions))
      end
    end
  end
end

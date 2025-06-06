defmodule Mockable do
  require Logger

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

    if Application.get_env(:mockable, module) do
      callback_specs =
        Module.get_attribute(module, :callback)
        |> Enum.map(fn {:callback, spec, _} ->
          case spec do
            {:"::", _, [{name, _, args}, _return_type]} ->
              {{name, length(args)}, spec}
          end
        end)
        |> Map.new()
        |> Map.take(Module.definitions_in(module, :def))

      wrapped_functions =
        for {{name, arity}, spec} <- callback_specs do
          args = Macro.generate_arguments(arity, __MODULE__)

          quote do
            defoverridable [{unquote(name), unquote(arity)}]

            @spec unquote(spec)
            def unquote(name)(unquote_splicing(args)) do
              implementation =
                Process.get({Mockable, unquote(module)}) ||
                  Application.get_env(:mockable, unquote(module))

              if implementation != unquote(module) do
                Mockable.log_implementation_usage(
                  implementation,
                  unquote(name),
                  unquote(arity),
                  unquote(module_string)
                )

                apply(implementation, unquote(name), [unquote_splicing(args)])
              else
                Mockable.log_implementation_usage(
                  implementation,
                  unquote(name),
                  unquote(arity),
                  unquote(module_string)
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

  if Application.compile_env(:mockable, :log, true) do
    def log_implementation_usage(implementation, function_name, arity, module) do
      Logger.debug("Using #{inspect(implementation)}.#{function_name}/#{arity} for #{module}")
    end
  else
    def log_implementation_usage(_implementation, _function_name, _arity, _module), do: :ok
  end
end

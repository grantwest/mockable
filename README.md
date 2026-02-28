# Mockable

[![Build Status](https://github.com/grantwest/mockable/actions/workflows/ci.yml/badge.svg)](https://github.com/grantwest/mockable/actions/workflows/ci.yml)
[![Version](https://img.shields.io/hexpm/v/mockable.svg)](https://hex.pm/packages/mockable)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/mockable/)
[![Download](https://img.shields.io/hexpm/dt/mockable.svg)](https://hex.pm/packages/mockable)
[![License](https://img.shields.io/badge/License-0BSD-blue.svg)](https://opensource.org/licenses/0bsd)
[![Last Updated](https://img.shields.io/github/last-commit/grantwest/mockable.svg)](https://github.com/grantwest/mockable/commits/main)

**Important:** This package is in maintenance mode. I suggest using [Mimic](https://hex.pm/packages/mimic) or [Req.Test](https://hexdocs.pm/req/Req.Test.html) for your mocking, they are much better.

Zero boilerplate implementation delegation.

## Example

use Mockable in a module:

```elixir
defmodule TemperatureClient do
  use Mockable

  @callback get_temperature(String.t()) :: integer()

  @impl true
  def get_temperature(city) do
    Req.get!("https://weather.com/temperatue/#{city}").body["temperature"]
  end
end
```

Configure the test environment (config/test.exs) to delegate function calls to the mock:

```elixir
config :mockable, [
  {TemperatureClient, TemperatureClientMock}
]
```

Optionally configure the dev environment (config/dev.exs) to delegate function calls to a stub:

```elixir
config :mockable, [
  {TemperatureClient, TemperatureClientStub},
  log: false
]
```

The `log` option shown above controls whether a log is emmitted for each invocation indicating the implementation used. If you are using mockable in prod builds for stubs/fakes in staging environments, you probably want to set `log: false` for your prod build.

If you don't configure a default implementation for a Mockable module at compile time, all Mockable code for that module will be completely eliminated from the build. It will be as if that module does not `use Mockable`.

Implement a dev stub like this:

```elixir
defmodule TemperatureClientStub do
  @behaviour TemperatureClient

  @impl true
  def get_temperature(city) do
    30
  end
end
```

### Testing Prod Implementation

There are a couple of options for running the production implementation in test.
The simplest is to use `Mockable.use/1` like this:

```elixir
defmodule TemperatureClientTest do
  use ExUnit.Case, async: true
  test "get_temperature" do
    Mockable.use(TemperatureClient)
    assert TemperatureClient.get_temperature("Dallas") |> is_number()
  end
end
```

Since `Mockable.use` sets process memory, it will not work for tests that use additional processes, such as integration/e2e tests. For these tests we can rely on the ownership features of Mox.

```elixir
defmodule MyIntegrationTest do
  use ExUnit.Case, async: true
  test "some useful test" do
    Mox.stub_with(TemperatureClientMock, TemperatureClient.Impl)
    assert MyApp.do_thing_that_uses_temperature() == :correct
  end
end
```

This works because when a module has `use Mockable` a new module is defined named `__MODULE__.Impl` that always runs the production implementation of the code. `__MODULE__.Impl` just serves as a pointer to the prod implementation no matter what is configured.

Why do we need this? TemperatureClient is always going to run the delegation logic. If it is configured to delegate to Mox and Mox is configured to stub_with TemperatureClient, it creates an infinite loop. TemperatureClient.Impl is a way to point Mox.stub_with directly at the prod implementation.

[See docs](https://hexdocs.pm/mockable/Mockable.html) for more information and examples.

## Details

Mockable works by using a `__before_compile__` macro to wrap each callback implementation in delegation logic. But it only does this if `:mockable` is configured for the module, thus it does not affect production code.

Mockable is not a mock framework. It works with the mock framework of your choice. It helps delegate function calls to mocks. If you are coming from OOP, Mockable serves a similar purpose to dependency injection in tests.

Features/Benefits:

- Zero boilerplate code
- Can be used with Exunit `async: true`
- Compatible with Mox/Hammox (and probably any other mocking library)
- Applies @callback as @spec on implementations to enable dialyzer checks
- Completely compiles out in prod builds, not requiring even an `Application.get_env`, making it suitable for frequently called functions
- Behaviour and implementation defined in the same module for easy finding/reading
- Only overrides callbacks, other functions defined within the Mockable module are not delegated and can be called as normal
- IDE "navigate to definition" features work as expected
- Flexible options for configuring delegation

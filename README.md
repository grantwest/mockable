# Mockable

[![Build Status](https://github.com/grantwest/mockable/actions/workflows/ci.yml/badge.svg)](https://github.com/grantwest/mockable/actions/workflows/ci.yml)
[![Version](https://img.shields.io/hexpm/v/mockable.svg)](https://hex.pm/packages/mockable)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/mockable/)
[![Download](https://img.shields.io/hexpm/dt/mockable.svg)](https://hex.pm/packages/mockable)
[![License](https://img.shields.io/badge/License-0BSD-blue.svg)](https://opensource.org/licenses/0bsd)
[![Last Updated](https://img.shields.io/github/last-commit/grantwest/mockable.svg)](https://github.com/grantwest/mockable/commits/main)

Zero boilerplate mock delegation.

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

The `log` option shown above controls whether a log is emmitted for each invocation indicating the implementation used. This is compiled out in prod builds.

DO NOT `config :mockable, ...` in prod builds. Not being configured is what sets it to compile out.

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

[See docs](https://hexdocs.pm/mockable/Mockable.html) for more information and examples.

## Details

Mockable works by using a `__before_compile__` macro to wrap each callback implementation in delegation logic. But it only does this if `:mockable` is configured, thus it does not affect production code.

Features/Benefits:

- Zero boilerplate code
- Can be used with Exunit `async: true`
- Compatible with Mox/Hammox (and probably any other mocking library)
- Applies @callback as @spec on implementations to enable dialyzer checks
- Configurable with Application environment & process memory
- Completely compiles out in prod builds, not requiring even an `Application.get_env`, making it suitable for frequently called functions
- Behaviour and implementation defined in the same module for easy finding/reading
- Only overrides callbacks, other functions defined within the Mockable module are not delegated and can be called as normal

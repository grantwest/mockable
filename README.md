# Mockable

[![Build Status](https://github.com/grantwest/mockable/actions/workflows/ci.yml/badge.svg)](https://github.com/grantwest/mockable/actions/workflows/ci.yml)
[![Version](https://img.shields.io/hexpm/v/mockable.svg)](https://hex.pm/packages/mockable)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/mockable/)
[![Download](https://img.shields.io/hexpm/dt/mockable.svg)](https://hex.pm/packages/mockable)
[![License](https://img.shields.io/badge/License-0BSD-blue.svg)](https://opensource.org/licenses/0bsd)
[![Last Updated](https://img.shields.io/github/last-commit/grantwest/mockable.svg)](https://github.com/grantwest/mockable/commits/main)

Mox/Hammox compatible mocking with minimal configuration and zero boilerplate.

Features/Benefits:

- Zero boilerplate code
- Configurable with Application environment & process memory
- Completely compiles out in prod builds, not requiring even an `Application.get_env`, making it suitable for frequently called functions
- Behaviour and implementation defined in the same module for easy finding/reading
- Only overrides callbacks, other functions defined within the Mockable module are not delegated and can be called as normal

Mockable works by using a `__before_compile__` macro to wrap each callback implementation in delegation logic. But it only does this if `:mockable` is configured, thus it does not affect production code.

## Example

use Mockable in your module:

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

Configure your test environment to route function calls to your mock:

```elixir
config :mockable, [
  {TemperatureClient, TemperatureClientMock}
]
```

Optionally configure your dev environment to route function calls to a stub:

```elixir
config :mockable, [
  {TemperatureClient, TemperatureClientStub},
  log: false
]
```

The log option shown above controls the debug level log output that indicates the implementation used for each invocation. This is compiled out in prod builds.

You should NOT `config :mockable ...` in your prod builds. Not being configured is what sets it to compile out.

[See docs](https://hexdocs.pm/mockable/Mockable.html) for more information and examples.

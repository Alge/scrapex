# config/test.exs
import Config

# Override the logger config for tests
config :logger,
  level: :warn  # This will reduce log noise during tests

# Keep your custom formatter but reduce the level
config :logger, :console,
  format: {Scrapex.LogFormatter, :format},
  level: :warn,  # Only show warnings and errors by default
  metadata: [:module, :line]

# Most importantly - configure ExUnit to capture logs
config :ex_unit,
  capture_log: true

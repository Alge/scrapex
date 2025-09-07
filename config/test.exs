# config/test.exs
import Config

# Override the logger config for tests
config :logger,
  # This will reduce log noise during tests
  level: :warn

# Keep your custom formatter but reduce the level
config :logger, :console,
  format: {Scrapex.LogFormatter, :format},
  # Only show warnings and errors by default
  level: :warn,
  metadata: [:module, :line]

# Most importantly - configure ExUnit to capture logs
config :ex_unit,
  capture_log: true

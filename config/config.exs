# config/config.exs
import Config

# Basic logger - just console output for now
config :logger,
  backends: [:console],
  #level: :info
  level: :debug

config :logger, :console,
  format: {Scrapex.LogFormatter, :format},
  level: :debug,
  metadata: [:module, :line]

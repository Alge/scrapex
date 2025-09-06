# ScrapEx

A ScrapScript interpreter written in Elixir.

## Setup

```bash
git clone <your-repo-url>
cd scrapex
mix deps.get
mix dialyzer --plt  # One-time setup
```

## Development

```bash
mix test              # Run tests
mix format            # Format code
mix check             # Quality checks
mix check.strict      # Type analysis + security
mix check.ci          # Full CI pipeline
```

## Tools

```bash
mix credo             # Code quality
mix dialyzer          # Type analysis  
mix sobelow           # Security scan
mix coveralls.html    # Test coverage
```

## Structure

```
lib/scrapex/
├── lexer.ex          # Tokenizer
├── token.ex          # Token types
└── ...               # TODO: parser, evaluator

test/
├── lexer_test.exs
└── scrapex_test.exs
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/scrapex>.


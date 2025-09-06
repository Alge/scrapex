# .credo.exs
%{
  configs: [
    %{
      name: "default",
      strict: false,  # More lenient for daily development
      files: %{
        included: ~w[lib test],
        excluded: []
      },
      checks: %{
        enabled: [
          # Consistency checks (good to have)
          {Credo.Check.Consistency.ExceptionNames, []},
          {Credo.Check.Consistency.LineEndings, []},
          {Credo.Check.Consistency.ParameterPatternMatching, []},
          {Credo.Check.Consistency.SpaceAroundOperators, []},
          {Credo.Check.Consistency.SpaceInParentheses, []},
          {Credo.Check.Consistency.TabsOrSpaces, []},

          # Design checks (relaxed)
          {Credo.Check.Design.AliasUsage, [priority: :low]},
          # Skip DuplicatedCode - too noisy for small projects
          # Skip TagHelper - not commonly used
          # Allow TODOs in development

          # Readability (reasonable limits)
          {Credo.Check.Readability.FunctionNames, []},
          {Credo.Check.Readability.LargeNumbers, []},
          {Credo.Check.Readability.MaxLineLength, [max_length: 120]}, # More reasonable
          {Credo.Check.Readability.ModuleAttributeNames, []},
          # Don't require module docs for everything
          {Credo.Check.Readability.ModuleNames, []},
          {Credo.Check.Readability.ParenthesesInCondition, []},
          {Credo.Check.Readability.PredicateFunctionNames, []},
          {Credo.Check.Readability.PreferImplicitTry, []},
          {Credo.Check.Readability.RedundantBlankLines, []},
          {Credo.Check.Readability.Semicolons, []},
          {Credo.Check.Readability.SpaceAfterCommas, []},
          {Credo.Check.Readability.StringSigils, []},
          {Credo.Check.Readability.TrailingBlankLine, []},
          {Credo.Check.Readability.TrailingWhiteSpace, []},
          {Credo.Check.Readability.UnnecessaryAliasExpansion, []},
          {Credo.Check.Readability.VariableNames, []},

          # Refactoring (relaxed limits)
          {Credo.Check.Refactor.CyclomaticComplexity, [max_complexity: 15]}, # More lenient
          {Credo.Check.Refactor.FunctionArity, [max_arity: 8]}, # More reasonable
          {Credo.Check.Refactor.LongQuoteBlocks, []},
          {Credo.Check.Refactor.MatchInCondition, []},
          {Credo.Check.Refactor.NegatedConditionsInUnless, []},
          {Credo.Check.Refactor.NegatedConditionsWithElse, []},
          {Credo.Check.Refactor.Nesting, [max_nesting: 4]}, # Slightly more lenient
          {Credo.Check.Refactor.UnlessWithElse, []},

          # Important warnings (keep these)
          {Credo.Check.Warning.ApplicationConfigInModuleAttribute, []},
          {Credo.Check.Warning.BoolOperationOnSameValues, []},
          {Credo.Check.Warning.ExpensiveEmptyEnumCheck, []},
          {Credo.Check.Warning.IExPry, [priority: :high]}, # Catch debug code
          {Credo.Check.Warning.IoInspect, [priority: :high]}, # Catch debug code
          {Credo.Check.Warning.LazyLogging, []},
          {Credo.Check.Warning.MapGetUnsafePass, []},
          {Credo.Check.Warning.OperationOnSameValues, []},
          {Credo.Check.Warning.OperationWithConstantResult, []},
          {Credo.Check.Warning.RaiseInsideRescue, []},
          {Credo.Check.Warning.UnusedEnumOperation, []},
          {Credo.Check.Warning.UnusedFileOperation, []},
          {Credo.Check.Warning.UnusedKeywordOperation, []},
          {Credo.Check.Warning.UnusedListOperation, []},
          {Credo.Check.Warning.UnusedPathOperation, []},
          {Credo.Check.Warning.UnusedRegexOperation, []},
          {Credo.Check.Warning.UnusedStringOperation, []},
          {Credo.Check.Warning.WrongTestFileExtension, []}
        ],
        disabled: [
          # Disable overly pedantic checks
          {Credo.Check.Design.TagTODO, []}, # Allow TODOs
          {Credo.Check.Design.DuplicatedCode, []}, # Too noisy
          {Credo.Check.Design.TagHelper, []}, # Rarely relevant
          {Credo.Check.Readability.AliasOrder, []}, # Pedantic
          {Credo.Check.Readability.ModuleDoc, []}, # Don't require docs everywhere
          {Credo.Check.Refactor.CondStatements, []}, # Sometimes cond is clearer

          # Incompatible with Elixir 1.18+
          {Credo.Check.Warning.LazyLogging, []},
        ]
      }
    }
  ]
}

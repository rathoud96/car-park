%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "test/"],
        excluded: ["deps/", "config/", "priv/"]
      },
      checks: [
        # Consistency Checks
        {Credo.Check.Consistency.ExceptionNames},
        {Credo.Check.Consistency.LineEndings},
        {Credo.Check.Consistency.ParameterPatternMatching},
        {Credo.Check.Consistency.SpaceAroundOperators},
        {Credo.Check.Consistency.SpaceInParentheses},
        {Credo.Check.Consistency.TabsOrSpaces},

        # Design Checks
        {Credo.Check.Design.AliasUsage, false},
        {Credo.Check.Design.DuplicatedCode, mass_threshold: 16, nodes_threshold: 2},
        {Credo.Check.Design.TagTODO, exit_status: 2},
        {Credo.Check.Design.TagFIXME},

        # Readability Checks
        {Credo.Check.Readability.AliasOrder},
        {Credo.Check.Readability.BlockPipe},
        {Credo.Check.Readability.FunctionNames},
        {Credo.Check.Readability.LargeNumbers},
        {Credo.Check.Readability.MaxLineLength, max_length: 120},
        {Credo.Check.Readability.ModuleAttributeNames},
        {Credo.Check.Readability.ModuleDoc, false},
        {Credo.Check.Readability.ModuleNames},
        {Credo.Check.Readability.MultiAlias},
        {Credo.Check.Readability.ParenthesesInCondition},
        {Credo.Check.Readability.ParenthesesOnZeroArityDefs},
        {Credo.Check.Readability.PredicateFunctionNames},
        {Credo.Check.Readability.PreferImplicitTry},
        {Credo.Check.Readability.RedundantBlankLines},
        {Credo.Check.Readability.Semicolons},
        {Credo.Check.Readability.SpaceAfterCommas},
        {Credo.Check.Readability.StringSigils},
        {Credo.Check.Readability.TrailingBlankLine},
        {Credo.Check.Readability.TrailingWhiteSpace},
        {Credo.Check.Readability.UnnecessaryAliasExpansion},
        {Credo.Check.Readability.VariableNames},

        # Refactoring Opportunities
        {Credo.Check.Refactor.ABCSize, max_size: 60},
        {Credo.Check.Refactor.AppendSingleItem},
        {Credo.Check.Refactor.CondStatements},
        {Credo.Check.Refactor.CyclomaticComplexity},
        {Credo.Check.Refactor.DoubleBooleanNegation},
        {Credo.Check.Refactor.EndExpressions},
        {Credo.Check.Refactor.FilterCount},
        {Credo.Check.Refactor.FilterReject},
        {Credo.Check.Refactor.FunctionArity},
        {Credo.Check.Refactor.InlineFunctionOutOfContext},
        {Credo.Check.Refactor.IoPuts},
        {Credo.Check.Refactor.LongQuoteBlocks},
        {Credo.Check.Refactor.MapInto},
        {Credo.Check.Refactor.MapJoin},
        {Credo.Check.Refactor.MatchInCondition},
        {Credo.Check.Refactor.ModuleDependencies},
        {Credo.Check.Refactor.NegatedConditionsInUnless},
        {Credo.Check.Refactor.NegatedConditionsWithElse},
        {Credo.Check.Refactor.Nesting},
        {Credo.Check.Refactor.PipeChainStart},
        {Credo.Check.Refactor.RedundantWithClause},
        {Credo.Check.Refactor.RejectingFilter},
        {Credo.Check.Refactor.RepeatedConditionalCalls},
        {Credo.Check.Refactor.UnlessWithElse},

        # Warnings
        {Credo.Check.Warning.ApplicationConfigInModuleAttribute},
        {Credo.Check.Warning.BoolOperationOnSameValues},
        {Credo.Check.Warning.ExpensiveEmptyEnumCheck},
        {Credo.Check.Warning.IExPry},
        {Credo.Check.Warning.IoInspect},
        {Credo.Check.Warning.LazyLogging},
        {Credo.Check.Warning.LeakyEnvironment},
        {Credo.Check.Warning.MapGetUnsafePass},
        {Credo.Check.Warning.MixEnv},
        {Credo.Check.Warning.OperationOnSameValues},
        {Credo.Check.Warning.OperationWithConstantResult},
        {Credo.Check.Warning.RaiseInsideRescue},
        {Credo.Check.Warning.SpecWithType},
        {Credo.Check.Warning.UnsafeExec},
        {Credo.Check.Warning.UnsafeToAtom},
        {Credo.Check.Warning.UnusedEnumOperation},
        {Credo.Check.Warning.UnusedFileOperation},
        {Credo.Check.Warning.UnusedKeywordOperation},
        {Credo.Check.Warning.UnusedListOperation},
        {Credo.Check.Warning.UnusedPathOperation},
        {Credo.Check.Warning.UnusedRegexOperation},
        {Credo.Check.Warning.UnusedStringOperation},
        {Credo.Check.Warning.UnusedTupleOperation},
        {Credo.Check.Warning.UselessIf},
        {Credo.Check.Warning.UselessQuote},

        # Custom Checks for Elixir/Phoenix Best Practices
        {Credo.Check.Warning.UnusedVariable, false},
        {Credo.Check.Readability.ModuleDoc, false},
        {Credo.Check.Refactor.ABCSize, max_size: 60},
        {Credo.Check.Refactor.CyclomaticComplexity, max_complexity: 10},
        {Credo.Check.Refactor.Nesting, max_nesting: 3},
        {Credo.Check.Readability.MaxLineLength, max_length: 120}
      ]
    }
  ]
}

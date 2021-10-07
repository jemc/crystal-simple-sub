module SimpleSub
  struct CompactType
    alias TypeVariable = Typer::TypeVariable
    alias TypePrimitive = Typer::TypePrimitive
    alias TypeFunction = Typer::TypeFunction

    property vars : Set(TypeVariable)?
    property prims : Set(TypePrimitive)?
    property rec : Hash(String, CompactType)?
    property fn : Array(CompactType)?

    def initialize(@vars = nil, @prims = nil, @rec = nil, @fn = nil)
    end

    def show; String.build { |io| show(io) } end
    def show(io : IO, polarity = true)
      if (fn = @fn)
        io << "("
        fn[0].show(io)
        # TODO: show more than one param
        io << " -> "
        fn[-1].show(io)
        io << ")"
      elsif (rec = @rec)
        raise NotImplementedError.new("show for #{inspect}")
      elsif @prims || @vars
        is_first = true
        sep = polarity ? " | " : " & "

        @prims.try(&.each { |x|
          io << sep unless is_first; x.show(io); is_first = false
        })
        @vars.try(&.each { |x|
          io << sep unless is_first; x.show(io); is_first = false
        })
      else
        io << (polarity ? "T" : "⊥")
      end
    end

    alias RecursiveVars = Hash(TypeVariable, CompactType)

    protected def mutably_accept(
      input : Typer::Type,
      polarity = true,
      recursive_vars = RecursiveVars.new,
      parents = Set(TypeVariable).new,
    ) : CompactType
      # TODO: Handle recursive and "in process", and "parents" cases.
      case input
      when TypePrimitive
        (@prims ||= Set(TypePrimitive).new).not_nil!.add(input)
      when TypeFunction
        @fn = [
          self.class.from(input.param.value, !polarity, recursive_vars),
          self.class.from(input.ret.value, polarity, recursive_vars),
        ]
      when TypeVariable
        (@vars ||= Set(TypeVariable).new).not_nil!.add(input)
        (
          polarity ? input.lower_bounds : input.upper_bounds
        ).try(&.each { |bound|
          mutably_accept(
            bound,
            polarity,
            recursive_vars,
            parents.dup.add(input), # TODO: no dup?
          )
        })
      else
        raise NotImplementedError.new(input.inspect)
      end

      self
    end

    def self.from(
      input : Typer::Type,
      polarity = true,
      recursive_vars = RecursiveVars.new,
      parents = Set(TypeVariable).new,
    ) : CompactType
      new.mutably_accept(input, polarity, parents)
    end

    def self.simplified_from(input : Typer::Type, polarity = true)
      # Begin by compacting the input type, also gaining access to the set
      # of recursive variables present in the input type as it compacts.
      orig_recursive_vars = RecursiveVars.new
      type = from(input, polarity, orig_recursive_vars)

      # TODO: Make use of this:
      recursive_vars = {} of TypeVariable => (-> CompactType)

      # The set of "all variables" starts with the list of recursive variables.
      # As we analyze, we will add all of the other variables we encounter.
      # TODO: We could consider moving this into the original "from" step?
      all_vars = orig_recursive_vars.each_key.to_set

      # TODO: recursive_vars

      # TODO: Document
      co_occurrences = {} of {Bool, TypeVariable} => Set(Typer::Type)

      type.analyze_co_occurrences(
        polarity, orig_recursive_vars, all_vars, co_occurrences,
      )

      # Here's where we will store information about our plan to make
      # variable substitutions, sometimes replacing one variable with another,
      # and at other times removing a variable entirely (when nil in the map).
      var_substs = {} of TypeVariable => TypeVariable?

      # Mark variables for removal if they occur only in one polarity.
      all_vars.each { |var|
        # If this variable is recursive, we can't remove it.
        next if recursive_vars.has_key?(var)

        # If this variable occurs in both positive and negative polarity,
        # we will not remove it, because that would remove type information.
        positive = co_occurrences[{true, var}]?
        negative = co_occurrences[{false, var}]?
        next if positive && negative

        # Otherwise, we can plan to remove this variable.
        var_substs[var] = nil
      }

      type = type.mutably_perform_var_substs(var_substs)

      type
    end

    protected def analyze_co_occurrences(
      polarity = true,
      orig_recursive_vars = RecursiveVars.new,
      all_vars = Set(TypeVariable),
      co_occurrences = Hash({Bool, TypeVariable}, Set(Typer::Type)),
    )
      type = self

      type.vars.try(&.each { |var|
        all_vars.add(var)

        new_occs = Set(Typer::Type).new
        type.vars.try(&.each { |v| new_occs.add(v) })
        type.prims.try(&.each { |p| new_occs.add(p) })

        existing_occs = co_occurrences[{polarity, var}]?
        if existing_occs
          # TODO: More efficient filter-in-place of existing_occs
          co_occurrences[{polarity, var}] = existing_occs & new_occs
        else
          co_occurrences[{polarity, var}] = new_occs
        end

        if orig_recursive_vars.has_key?(var)
          raise NotImplementedError.new("https://github.com/LPTK/simple-sub/blob/4cae4ee8b2b565fa2590bff9f1a1d171c8e0a5bd/shared/src/main/scala/simplesub/TypeSimplifier.scala#L204-L211")
        end
      })

      type.fn.try { |fn|
        fn[0...-1].each(&.analyze_co_occurrences(
          !polarity, orig_recursive_vars, all_vars, co_occurrences
        ))
        fn[-1].analyze_co_occurrences(
          polarity, orig_recursive_vars, all_vars, co_occurrences
        )
      }

      type.rec.try(&.values.each(&.analyze_co_occurrences(
        polarity, orig_recursive_vars, all_vars, co_occurrences
      )))
    end

    protected def mutably_perform_var_substs(
      var_substs : Hash(TypeVariable, TypeVariable?)
    ) : CompactType
      # TODO: More efficient compact_map! in place?
      @vars = @vars.try(&.compact_map { |var| var_substs[var] rescue var }.to_set)
      @vars = nil if @vars.try(&.empty?)

      @fn.try(&.map!(&.mutably_perform_var_substs(var_substs)))

      @rec.try(&.transform_values!(&.mutably_perform_var_substs(var_substs)))

      self
    end
  end
end

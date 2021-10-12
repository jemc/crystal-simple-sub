module SimpleSub
  class Typer
    # TODO: Use a persistent data structure instead of standard mutable Hash.
    alias Ctx = Hash(String, Type)

    def initialize
      @next_var_uid = -1
      @ctx_builtins = Ctx.new

      # Set up the builtin named types known in the ambient context.
      @ctx_builtins["true"] = TypePrimitive::BOOL
      @ctx_builtins["false"] = TypePrimitive::BOOL
      @ctx_builtins["not"] = TypeFunction.new(
        TypePrimitive::BOOL,
        TypePrimitive::BOOL
      )

      if_value_type = fresh_var(1)
      @ctx_builtins["if"] = TypePolymorphic.new(0,
        TypeFunction.new(
          TypePrimitive::BOOL,
          TypeFunction.new(
            if_value_type,
            TypeFunction.new(if_value_type, if_value_type),
          )
        )
      )
    end

    private def fresh_var(level)
      TypeVariable.new(@next_var_uid += 1, level)
    end

    def infer_type(term : Term)
      type_term(term, @ctx_builtins, 0)
    end

    private def type_term(term : Term, ctx : Ctx, level : Int32) : SimpleType
      case term
      when TermLit
        TypePrimitive::INT
      when TermVar
        t = ctx[term.name]?

        raise Error.new \
          "#{term.inspect} is not known within ctx: #{ctx.inspect}" \
            unless t

        instantiated(t, level)
      when TermLam
        param_type = fresh_var(level)
        ret_type = type_term(
          term.body.value,
          ctx.merge({ term.param_name => param_type }),
          level
        )
        TypeFunction.new(param_type, ret_type)
      when TermApp
        fn_type = type_term(term.fn.value, ctx, level)
        arg_type = type_term(term.arg.value, ctx, level)
        fresh_var(level).tap { |res_type|
          constrain(fn_type, TypeFunction.new(arg_type, res_type))
        }
      # TODO: Handle the rest of the term kinds.
      else
        raise NotImplementedError.new(term.inspect)
      end
    end

    private def constrain(
      sub : Type,
      sup : Type,
      seen_vars = Set({Type, Type}).new,
    )
      # If the types are identical, there is nothing to be done.
      return if sub == sup

      # Avoid doing duplicate work: if one side or the other is a type variable,
      # check the cache of already constrained type variables, and bail out
      # if we've already started constraining the given variable against the
      # given sub- or super-type it is being constrained with here.
      if sub.is_a?(TypeVariable) || sup.is_a?(TypeVariable)
        return if seen_vars.includes?({sub, sup})
        seen_vars.add({sub, sup})
      end

      if sub.is_a?(TypeFunction) && sup.is_a?(TypeFunction)
        # If both sides are functions, they are compatible if and only if
        # the return types and parameter types are compatible with one another.
        # Return types are covariant and parameter types are contravariant.
        constrain(sub.ret, sup.ret)
        constrain(sup.param, sub.param)
      # elsif sub.is_a?(TypeRecord) && sup.is_a?(TypeRecord)
      #   raise NotImplementedError.new("constrain TypeRecord")
      elsif sub.is_a?(TypeVariable) && sup.level <= sub.level
        # If the subtype is a variable at or above the level of the supertype,
        # collect the supertype into the bounds of the subtype variable.
        sub.upper_bounds << sup
        sub.lower_bounds.try(&.each { |b| constrain(b, sup, seen_vars) })
      elsif sup.is_a?(TypeVariable) && sub.level <= sup.level
        # If the supertype is a variable at or above the level of the subtype,
        # collect the subtype into the bounds of the supertype variable.
        sup.lower_bounds << sub
        sup.upper_bounds.try(&.each { |b| constrain(sub, b, seen_vars) })
      elsif sub.is_a?(TypeVariable)
        raise NotImplementedError.new("constrain sub variable across levels")
      elsif sup.is_a?(TypeVariable)
        raise NotImplementedError.new("constrain sup variable across levels")
      else
        raise NotImplementedError.new("need nice user-facing error here")
      end
    end

    private def instantiated(t : Type, level : Int32) : SimpleType
      case t
      when TypePolymorphic then freshened_above(t.body, t.level, level)
      when SimpleType      then t
      else raise NotImplementedError.new("instantiated for #{t.show}")
      end
    end

    private def freshened_above(
      t : SimpleType,
      limit : Int32,
      fresh_level : Int32,
      already_freshened = {} of TypeVariable => TypeVariable,
    ) : SimpleType
      return t if t.level <= limit

      case t
      when TypePrimitive then t
      when TypeFunction
        TypeFunction.new(
          freshened_above(t.param, limit, fresh_level, already_freshened),
          freshened_above(t.ret, limit, fresh_level, already_freshened),
        )
      when TypeVariable
        already = already_freshened[t]?
        return already if already

        already_freshened[t] = var = fresh_var(fresh_level)

        # We need to reverse before freshening so that the fresh variable
        # creation order will happen in the same order as the originals,
        # so that simplifying, which is order-dependent, can happen as intended.
        # TODO: Create a specialized Array#map_backwards! method for efficiency.
        var.lower_bounds = t.lower_bounds.reverse_each.map { |inner|
          freshened_above(inner, limit, fresh_level, already_freshened)
        }.to_a.reverse
        var.upper_bounds = t.upper_bounds.reverse_each.map { |inner|
          freshened_above(inner, limit, fresh_level, already_freshened)
        }.to_a.reverse

        var
      else
        raise NotImplementedError.new("freshened_above for #{t.show}")
      end
    end
  end
end

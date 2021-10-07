module SimpleSub
  class Typer
    # TODO: Use a persistent data structure instead of standard mutable Hash.
    alias Ctx = Hash(String, Type)

    CTX_BUILTINS = Ctx.new # TODO: Add the builtin types.

    def initialize
      @next_var_uid = 0
    end

    private def fresh_var(level)
      TypeVariable.new(@next_var_uid += 1, level)
    end

    def infer_type(term : Term)
      type_term(term, CTX_BUILTINS, 0)
    end

    private def type_term(term : Term, ctx : Ctx, level : Int32) : Type
      case term
      when TermLit
        TypePrimitive::INT
      when TermVar
        ctx[term.name]? || raise Error.new(
          "#{term.inspect} is not known within ctx: #{ctx.inspect}"
        )
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
        constrain(sub.ret.value, sup.ret.value)
        constrain(sup.param.value, sub.param.value)
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
  end
end

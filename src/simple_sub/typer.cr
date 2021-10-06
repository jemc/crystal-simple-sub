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

    private def type_term(term : Term, ctx : Ctx, level : Int32)
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

      # TODO: Handle the rest of the term kinds.
      else
        raise NotImplementedError.new(term.inspect)
      end
    end
  end
end

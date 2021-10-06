module SimpleSub
  class Typer
    def type_term(term : Term)
      case term
      when TermLit
        TypePrimitive::INT
      else raise NotImplementedError.new(term.inspect)
      end
    end
  end
end

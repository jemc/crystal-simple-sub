module SimpleSub
  abstract struct Term
    # Convenience method for more succinct instantiation in tests.
    def self.[](*args); new(*args) end
  end

  struct TermLit < Term
    property value : Int32
    def initialize(@value)
    end

    def pretty_print(format : PrettyPrint)
      @value.pretty_print(format)
    end
  end

  struct TermVar < Term
    property name : String
    def initialize(@name)
    end

    def pretty_print(format : PrettyPrint)
      format.text(@name)
    end
  end

  struct TermLam < Term
    property param_name : String # TODO: extend to allow multiple params
    property body : StructRef(Term)
    def initialize(@param_name, body)
      @body = StructRef(Term).new(body)
    end

    def pretty_print(format : PrettyPrint)
      format.surround("(fn", ")", left_break: " ", right_break: nil) {
        format.text(@param_name)
        format.text(" ->")
        format.breakable(" ")
        @body.value.pretty_print(format)
      }
    end
  end

  struct TermApp < Term
    property fn : StructRef(Term)
    property arg : StructRef(Term) # TODO: extend to allow multiple args
    def initialize(fn, arg)
      @fn = StructRef(Term).new(fn)
      @arg = StructRef(Term).new(arg)
    end

    def pretty_print(format : PrettyPrint)
      fn.value.pretty_print(format)
      format.surround("(", ")", left_break: "", right_break: nil) {
        @arg.value.pretty_print(format)
      }
    end
  end
end

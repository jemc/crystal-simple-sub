module SimpleSub
  abstract struct Term
  end

  struct TermLit < Term
    property value : Int32
    def initialize(@value)
    end
  end

  struct TermVar < Term
    property name : String
    def initialize(@name)
    end
  end

  struct TermLam < Term
    property param_name : String # TODO: extend to allow multiple params
    property body : StructRef(Term)
    def initialize(@param_name, body)
      @body = StructRef(Term).new(body)
    end
  end

  struct TermApp < Term
    property fn : StructRef(Term)
    property arg : StructRef(Term) # TODO: extend to allow multiple args
    def initialize(fn, arg)
      @fn = StructRef(Term).new(fn)
      @arg = StructRef(Term).new(arg)
    end
  end
end

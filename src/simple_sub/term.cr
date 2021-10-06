module SimpleSub
  abstract struct Term
  end

  struct TermLit < Term
    property value : Int32
    def initialize(@value)
    end
  end
end

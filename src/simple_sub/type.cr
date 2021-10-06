module SimpleSub
  abstract class Type
    abstract def show(io : IO)
    def show
      String.build { |io| show(io) }
    end
  end

  class TypePrimitive < Type
    property name : String
    def initialize(@name)
    end

    def show(io : IO)
      io << @name
    end

    INT = TypePrimitive.new("int")
  end
end

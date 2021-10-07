class SimpleSub::Typer
  abstract struct Type
    abstract def level : Int32

    abstract def show(io : IO)
    def show
      String.build { |io| show(io) }
    end
  end

  struct TypePrimitive < Type
    property name : String
    property level : Int32
    def initialize(@name)
      @level = 0
    end

    def show(io : IO)
      io << @name
    end

    INT = TypePrimitive.new("int")
    BOOL = TypePrimitive.new("bool")
  end

  struct TypeFunction < Type
    property param : StructRef(Type) # TODO: extend to allow multiple params
    property ret : StructRef(Type)
    def initialize(param, ret)
      @param = StructRef(Type).new(param)
      @ret = StructRef(Type).new(ret)
    end

    def level : Int32
      Math.max(@param.level, @ret.level)
    end

    def show(io : IO)
      io << "("
      @param.show(io)
      io << " -> "
      @ret.show(io)
      io << ")"
    end
  end

  # A type variable living at a certain polymorphism level `level`, with mutable bounds.
  # Invariant: Types appearing in the bounds never have a level higher than this variable's `level`.
  struct TypeVariable < Type
    property uid : Int32
    property level : Int32
    property lower_bounds = [] of Type
    property upper_bounds = [] of Type
    def initialize(@uid, @level)
    end

    def show(io : IO)
      io << "α"
      uid.inspect(io)
      io << "'" * @level
    end
  end
end

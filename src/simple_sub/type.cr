class SimpleSub::Typer
  abstract class Type
    abstract def level : Int32

    abstract def show(io : IO)
    def show
      String.build { |io| show(io) }
    end

    abstract def instantiated : SimpleType
  end

  abstract class SimpleType < Type
    # The instantiation of any SimpleType is just the SimpleType itself.
    def instantiated : SimpleType
      self
    end
  end

  class TypePrimitive < SimpleType
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

  class TypeFunction < SimpleType
    property param : SimpleType # TODO: extend to allow multiple params
    property ret : SimpleType
    def initialize(@param, @ret)
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
  class TypeVariable < SimpleType
    property uid : Int32
    property level : Int32
    property lower_bounds = [] of SimpleType
    property upper_bounds = [] of SimpleType
    def initialize(@uid, @level)
    end

    def show(io : IO)
      io << "α"
      uid.inspect(io)
      io << "'" * @level
    end
  end

  # A type with universally quantified type variables
  # (by convention, those variables of level greater than `level` are considered quantified). */
  #
  # This is the only Type we define which does not a SimpleType.
  class TypePolymorphic < Type
    property level : Int32
    property body : SimpleType
    def initialize(@level, @body)
    end

    def show(io : IO)
      raise NotImplementedError.new("TypePolymorphic.show")
    end

    def instantiated : SimpleType
      raise NotImplementedError.new("TypePolymorphic.instantiated")
    end
  end
end

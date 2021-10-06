module SimpleSub
  abstract struct Type
    abstract def level : Int32

    abstract def show(io : IO)
    def show
      String.build { |io| show(io) }
    end
  end

  struct TypeTop < Type
    def level : Int32; 0 end
    def show(io : IO); io << "T" end
  end

  struct TypeBottom < Type
    def level : Int32; 0 end
    def show(io : IO); io << "⊥" end
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
      Math.max(@param, @ret)
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
    def initialize(@uid, @level, @lower_bounds = nil, @upper_bounds = nil)
    end

    def show(io : IO)
      io << "α"
      uid.inspect(io)
      io << "'" * @level
    end
  end

  struct TypeUnion < Type
    property members = [] of Type
    def initialize(@members)
    end

    def level : Int32
      @members.map(&.level).max
    end

    def show(io : IO)
      raise NotImplementedError.new("TODO: #{self.class}.show")
    end

    def self.from(members)
      if members.nil? || members.empty?
        TypeBottom.new
      elsif members.size == 1
        members.first
      else
        new(members)
      end
    end
  end

  struct TypeInter < Type
    property members = [] of Type
    def initialize(@members)
    end

    def level : Int32
      @members.map(&.level).max
    end

    def show(io : IO)
      raise NotImplementedError.new("TODO: #{self.class}.show")
    end

    def self.from(members)
      if members.nil? || members.empty?
        TypeTop.new
      elsif members.size == 1
        members.first
      else
        new(members)
      end
    end
  end
end

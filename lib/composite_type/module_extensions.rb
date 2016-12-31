module CompositeType
  module ModuleExtensions
    def self.install! target = ::Module
      target.send(:include, self)
    end

    # Constructs a type of that matches an Enumerable with an element type.
    #
    # Array.of(String)
    def of t
      CompositeType::ContainerType[self, t]
    end

    # Constructs a type of Enumerable elements.
    #
    #   String.with(Integer, Float) === [ "foo", 1, 1.2 ]
    #   Hash.of(String.with(Integer))
    def with *types
      types.unshift(self)
      CompositeType::EnumeratedType[types]
    end

    # Constructs a type which can be A OR B.
    #
    #   String | Integer
    def | t
      CompositeType::DisjunctiveType[self, t]
    end

    # Constructs a type which must be A AND B.
    #
    #   Positive & Integer
    def & t
      CompositeType::ConjunctiveType[self, t]
    end

    # Constructs a type which must not be A.
    #
    #    ~ NilClass
    def ~@
      CompositeType::InverseType[self]
    end
  end
end


module CompositeType
  module ModuleExtensions
      # Constructs a type of that matches an Enumerable with an element type.
  #
  # Array.of(String)
  def of t
    CompositeType::ContainerType.new_cached(self, t)
  end


  # Constructs a type of Enumerable elements.
  #
  #   String.with(Integer, Float) === [ "foo", 1, 1.2 ]
  #   Hash.of(String.with(Integer))
  def with *types
    CompositeType::EnumeratedType.new_cached(self, *types)
  end

  # Constructs a type which can be A OR B.
  #
  #   Array.of(String|Integer)
  def | t
    case
    when t <= self
      self
    when self <= t
      t
    else
      a, b = self, t
      a, b = b, a if a.to_s > b.to_s
      CompositeType::DisjunctiveType.new_cached(a, b)
    end
  end

  # Constructs a type which must be A AND B.
  #
  # Array.of(Positive & Integer)
  def & t
    case
    when equal?(t)
      self
    else
      a, b = self, t
      a, b = b, a if a.to_s > b.to_s
      CompositeType::ConjunctiveType.new_cached(a, b)
    end
  end

  # Constructs a type which must not be A.
  #
  # Array.of(~ NilClass)
  def ~@
    case
    when x = CompositeType::InverseType::INVERSE_MAP[self]
      x
    when self.is_a?(CompositeType::InverseType)
      self._t.first
    else
      CompositeType::InverseType.new_cached(self)
    end
  end

  end
end


require 'thread'

class Module
  class CompositeType < self
    class Error < ::StandardError; end

    def self.new_cached *types
      key = [ self, types ]
      (Thread.current[:'Module::CompositeType.cache'] ||= { })[key] ||=
      CACHE_MUTEX.synchronize do
        CACHE[key] ||= new(types)
      end
    end
    CACHE = { }
    CACHE_MUTEX = Mutex.new

    def initialize types
      raise Error, "cannot create CompositeType from unamed object" unless types.all?{|x| x.name}
      @_t = types
    end
    attr_reader :_t
    def name; to_s; end
  end

  # Matches nothing.
  module VoidType
    def === x
      false
    end

    def >= t
      self == t
    end
  end
  Void = Class.new.extend(VoidType)

  class ContainerType < CompositeType
    def === x
      @_t[0] === x and x.all?{|e| @_t[1] === e }
    end

    def >= t
      super or
        t.is_a?(self.class) and @_t.zip(t._t).all?{|e1, e2| e1 >= e2 }
    end

    def to_s
      @to_s ||= "#{@_t[0]}.of(#{@_t[1]})".freeze
    end
  end

  # Constructs a type of that matches an Enumerable with an element type.
  #
  # Array.of(String)
  def of t
    ContainerType.new_cached(self, t)
  end

  class EnumeratedType < CompositeType
    def === x
      Enumerable === x and
        @_t.size == x.size and
        begin
          i = -1
          @_t.all?{|t| t === x[i += 1]}
        end
    end

    def >= t
      super or
        t.is_a?(self.class) and @_t.zip(t._t).all?{|e1, e2| e1 >= e2 }
    end

    def to_s
      @to_s ||= "#{@_t[0]}.with(#{@_t[1..-1] * ','})".freeze
    end
  end

  # Constructs a type of Enumerable elements.
  #
  #   String.with(Integer, Float) === [ "foo", 1, 1.2 ]
  #   Hash.of(String.with(Integer))
  def with *types
    EnumeratedType.new_cached(self, *types)
  end

  class DisjunctiveType < CompositeType
    def === x
      @_t[0] === x or @_t[1] === x
    end

    def >= t
      case
      when super
        true
      when t.is_a?(self.class)
        t._t.all?{|e2| @_t.any?{|e1| e1 >= e2}}
      else
        @_t.any?{|e1| e1 >= t}
      end
    end

    def to_s
      @to_s ||= "(#{@_t[0]}|#{@_t[1]})".freeze
    end
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
      DisjunctiveType.new_cached(a, b)
    end
  end

  class ConjunctiveType < CompositeType
    def === x
      @_t[0] === x and @_t[1] === x
    end

    def >= t
      case
      when super
        true
      when t.is_a?(self.class)
        t._t.all?{|e2| @_t.all?{|e1| e1 >= e2}}
      else
        @_t.all?{|e1| e1 >= t}
      end
    end

    def to_s
      @to_s ||= "(#{@_t[0]}&#{@_t[1]})".freeze
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
      ConjunctiveType.new_cached(a, b)
    end
  end

  class InverseType < CompositeType
    def === x
       ! (@_t[0] === x)
    end

    def >= t
      t.is_a?(self.class) and
        t._t[0] >= @_t[0]
    end

    def to_s
      @to_s ||= "(~#{@_t[0]})".freeze
    end

    INVERSE_MAP = {
    }
    def self.inverse(a, b)
      INVERSE_MAP[a] = b
      INVERSE_MAP[b] = a
    end
    inverse(Object, Void)
  end

  # Constructs a type which must not be A.
  #
  # Array.of(~ NilClass)
  def ~@
    case
    when x = InverseType::INVERSE_MAP[self]
      x
    when self.is_a?(InverseType)
      self._t.first
    else
      InverseType.new_cached(self)
    end
  end
end

# Numeric origin/continuum types.

# Objects that are Numeric or respond to :to_numeric.
module Numericlike
  def self.=== x
    case
    when Numeric === x
      x
    when x.respond_to?(:to_numeric)
      x.to_numeric
    end
  end
end

# Objects that are > 0.
module Positive
  def self.=== x
    x > 0 rescue nil
  end
end

# Objects that are < 0.
module Negative
  def self.=== x
    x < 0 rescue nil
  end
end

# Objects that are <= 0.
module NonPositive
  def self.=== x
    x <= 0 rescue nil
  end
  Module::InverseType.inverse(self, Positive)
end

# Objects that are Numericlike and >= 0.
module NonNegative
  def self.=== x
    x >= 0 rescue nil
  end
  Module::InverseType.inverse(self, Negative)
end

# Objects that behave like Hash.
module HashLike
  ::Hash.send(:include, self)
end

# Objects that can do IO.
#
# Note: IO and StringIO do not share a common ancestor Module
# that distingushes them as being capable of "IO".
# So we create one here -- devdriven.com 2013/11/14
require 'stringio'
module IOable
  ::IO.send(:include, self)
  ::StringIO.send(:include, self)
end

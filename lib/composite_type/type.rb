require 'thread'

module CompositeType
  class Type < ::Module
    def self.new_cached *types
      key = [ self, types ]
      (Thread.current[:'CompositeType:Type.cache'] ||= { })[key] ||=
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

  class ContainerType < Type
    def self.[] t1, t2
      new_cached(t1, t2)
    end

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

  class EnumeratedType < Type
    def self.[] types
      new_cached(*types)
    end

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

  class DisjunctiveType < Type
    def self.[] t0, t
      case
      when t <= t0
        t0
      when t0 <= t
        t
      else
        a, b = t0, t
        a, b = b, a if a.to_s > b.to_s
        new_cached(a, b)
      end
    end

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

  class ConjunctiveType < Type
    def self.[] t0, t
      case
      when t0.equal?(t)
        t0
      else
        a, b = t0, t
        a, b = b, a if a.to_s > b.to_s
        new_cached(a, b)
      end
    end

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

  class InverseType < Type
    def self.[] t
      case
      when x = INVERSE_MAP[t]
        x
      when t.is_a?(self)
        t._t.first
      else
        new_cached(t)
      end
    end

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
    def self.inverse!(a, b)
      INVERSE_MAP[a] = b
      INVERSE_MAP[b] = a
    end
    inverse!(Object, Void)
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
end

require 'composite_type'

module CompositeType
  # A declarative matching schema.
  class Schema < Module
    attr_accessor :proto, :match
    class << self
      alias :[] :new
    end

    def initialize proto
      @proto = proto
      @match = build proto
    end

    def === instance
      @match === instance
    end

    def build proto
      case proto
      when Schema, Base, Module
        proto
      when HashLike
        h = { }
        proto.each do | k, v |
          h[build(k)] = build(v)
        end
        HashType[h]
      when Enumerable
        EnumerableType[proto.map{|x| build x}]
      else
        Literal[proto]
      end
    end

    def inspect verbose = false
      return super() if verbose
      "#{self.class}[#{@proto.inspect}]"
    end

    module Ellipsis
      def self.=== instance
        true
      end
    end

    class Base
      attr_reader :matcher

      class << self
        alias :[] :new
      end

      def initialize proto
        @matcher = proto
      end

      def inspect verbose = false
        return super() if verbose
        "#{self.class}[#{@matcher.inspect}]"
      end
    end

    class Many < Base
      attr_reader :min, :max

      class << self
        alias :[] :new
      end

      def initialize proto, min = nil, max = nil
        @matcher = proto
        @min = min || 0
        @max = max
      end

      def === instance
        @matcher === instance
      end
    end

    class Optional < Many
      def initialize proto
        super(proto, 0, 1)
      end
    end

    class OneOrMore < Many
      def initialize proto
        super(proto, 1)
      end
    end

    class Literal < Base
      def === instance
        @matcher == instance
      end
    end

    class EnumerableType < Base
      def === instance
        return false unless Enumerable === instance
        i = 0
        @matcher.each do | et |
          case
          when Ellipsis == et
            return true
          when Many === et
            count = 0
            while i < instance.size && et === instance[i]
              i += 1
              count += 1
              break if et.max and count >= et.max
            end
            return false unless count >= et.min
          else
            return false unless i < instance.size && et === instance[i]
            i += 1
          end
        end
        i == instance.size
      end
    end

    class HashType < EnumerableType
      def === instance
        return false unless HashLike === instance
        i_min = false
        i = 0
        # binding.pry if ($break -= 1) > 0
        @matcher.each do | kt, vt |
          case
          when Ellipsis == kt
            i_min = true
          when Many === kt
            if count = match_min_max(instance, kt, vt, kt.min, kt.max)
              i += count
            else
              return false
            end
          when Literal === kt
            kt = kt.matcher
            return false unless instance.key?(kt) && vt === instance[kt]
            i += 1
          when Module === kt
            if count = match_min_max(instance, kt, vt, 1, 2) and count == 1
              i += count
            else
              return false
            end
          else
            return false unless instance.key?(kt) && vt === instance[kt]
            i += 1
          end
        end
        if i_min
          i <= instance.size
        else
          i == instance.size
        end
      end

      def match_min_max instance, kt, vt, min, max
        count = 0
        instance.each do | k, v |
          if kt === k && vt === v
            count += 1
            break if max and count >= max
          end
        end
        count >= min && count
      end
    end
  end
end

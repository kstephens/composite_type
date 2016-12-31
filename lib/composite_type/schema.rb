require 'composite_type'

module CompositeType
  # A declarative matching schema.
  class Schema
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

    class Optional < Base
      def === instance
        @matcher === instance
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
          when Optional === et
            if et === instance[i]
              i += 1
            end
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
        matches_min = false
        matches = 0
        binding.pry if ($break -= 1) > 0
        @matcher.each do | kt, vt |
          case
          when Ellipsis == kt
            matches_min = true
          when Optional === kt
            matches += instance.count do | k, v |
              if kt === k
                return false unless vt === v
                true
              end
            end
          when Module === kt && Module === vt
            return false if instance.empty?
            instance.each do | k, v |
              return false unless kt === k && vt === v
              matches += 1
            end
          when Literal === kt
            kt = kt.matcher
            return false unless instance.key?(kt) && vt === instance[kt]
            matches += 1
          else
            return false unless instance.key?(kt) && vt === instance[kt]
            matches += 1
          end
        end
        if matches_min
          matches <= instance.size
        else
          matches == instance.size
        end
      end
    end
  end
end

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
  CompositeType::InverseType.inverse!(self, Positive)
end

# Objects that are Numericlike and >= 0.
module NonNegative
  def self.=== x
    x >= 0 rescue nil
  end
  CompositeType::InverseType.inverse!(self, Negative)
end


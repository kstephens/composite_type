# CompositeType

Composite Types and Schema for Ruby

Modules (and the subclass Class) are often used as pattern matchers.

## Usage

Defining types through Modules:

    module Even
      def self.=== x
        Integer === x and x.even?
      end
    end
    Even === 2  # => true
    Even === 3  # => false

### Module Extensions

Logical operators: #|, #&, #~ compose types logically:

    (String | Symbol)    === :a   # => true
    (String | Symbol)    === "a"  # => true
    (String | Symbol)    === 1    # => false
    (Positive & Integer) ===  1   # => true
    (Positive & Integer) === -2   # => false
    (~ NilClass) === 1            # => true
    (~ NilClass) === nil          # => false

Composite types create dynamic Modules that define the #=== pattern matching operator.

Thus composite types can be used in "case" clauses:

    Odd = ~ Even
    case x
    when 0    then "zero"
    when Odd  then "odd"
    when Even then "even"
    end

Composite types are cached indefinitely, therefore anonymous Modules cannot be composed.

### Schema

Provides a basic library to interpret a Ruby data structure as a matchable schema:

   schema = Schema[ { Many[Symbol] => String } ]
   schema === { a: "b" }   # => true
   schema === { }          # => true
   schema === { 1 => 2 }   # => false

   schema = Schema[ { OneOrMore[Symbol] => String } ]
   schema === { a: "b" }   # => true
   schema === { }          # => false

### Basic Data Structures
 
Composite Types can be constructed to match data structures:

    h = { "a" => 1, "b" => :symbol }
    Hash.of(String.with(Integer|Symbol)) === h  # => true

    case h
    when Hash.of(String.with(Users))  ...
    when Hash.of(Symbol.with(Object)) ...
    end

See spec/lib/**/_spec.rb for more examples.

## Installation

Add this line to your application's Gemfile:

    gem 'composite_type'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install composite_type

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

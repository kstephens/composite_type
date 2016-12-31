module CompositeType
  class Error < ::StandardError; end
end

require 'composite_type/type'
require 'composite_type/module_extensions'
::Module.send(:include, CompositeType::ModuleExtensions)
require 'composite_type/numeric'

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

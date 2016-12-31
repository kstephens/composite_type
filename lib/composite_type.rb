module CompositeType
  class Error < ::StandardError; end
end

require 'composite_type/type'
require 'composite_type/module_extensions'
::Module.send(:include, CompositeType::ModuleExtensions)
require 'composite_type/numeric'


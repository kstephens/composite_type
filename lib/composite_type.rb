module CompositeType
  class Error < ::StandardError; end
end

require 'composite_type/type'
require 'composite_type/module_extensions'
CompositeType::ModuleExtensions.install!
require 'composite_type/numeric_types'


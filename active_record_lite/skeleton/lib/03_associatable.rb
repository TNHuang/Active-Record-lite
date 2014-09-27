require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    self.send("foreign_key=",  options[:foreign_key] || "#{name}_id".to_sym)
    self.send("class_name=", options[:class_name] || name.to_s.camelcase)
    self.send("primary_key=", options[:primary_key] || :id)
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    self.send("foreign_key=",  options[:foreign_key] || "#{self_class_name.underscore}_id".to_sym)
    self.send("class_name=", options[:class_name] || name.to_s.dingularize.camelcase)
    self.send("primary_key=", options[:primary_key] || :id)
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    # ...
    self.assoc_options[name] = BelongsToOptions.new(name, options)

    define_method(name) do
      options = self.class.assoc_options[name]

      key_value = self.send(options.foreign_key)

      options
        .model_class
        .where(options.primary_key => key_value)
        .first
    end
  end

  def has_many(name, options = {})
    # ...
    self.assoc_options[name] = BelongsToOptions.new(name, options)

    define_method(name) do
      options = self.class.assoc_options[name]
      key_value = self.send(options.primary_key)

      options
        .model_class
        .where(options.foreign_key => key_value)
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    @assoc_options ||= {}
    @assoc_options
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end

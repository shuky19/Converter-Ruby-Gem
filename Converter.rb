# This module helps converting between to instances
# of different classes
module Converter
  def self.included(base)
    base.extend(ClassConverter)
  end

  def self.convert(source, target_type)
    # Create new target instance
    target = target_type.new

    # Gets source Conversion definition
    conversion_properties = source.class.class_eval { @attribute_converter}

    # update each accessor on the target according to the conversion definition
    source.instance_variables.each do |var|
      var_name = var.to_s.delete('@').to_sym

      # Get the conversion definition for the current accessor if exists
      if convert_property = conversion_properties[var_name]
        target_property_name = convert_property.target_property_name.to_s.concat('=').to_sym

        # Convert from one type to another (by default doesn't do anything)
        target_value = convert_property.convert_block.call(source.send(var_name))
        target.send(target_property_name, target_value)
      end
    end

    target
  end

  def self.convertBack(target, source_type)
    # Create new target instance
    source = source_type.new

    # Gets source Conversion definition
    conversion_properties = source.class.class_eval { @attribute_converter }

    # update each accessor on the target according to the conversion definition
    source.methods.grep(/[a-zA-Z0-9]=$/).each do |var_name|
      var_name_trimmed = var_name.to_s.delete('=').to_sym

      # Get the conversion definition for the current accessor if exists
      if convert_property = conversion_properties[var_name_trimmed]
        target_property_name = convert_property.target_property_name

        # Convert from one type to another (by default doesn't do anything)
        source_value = convert_property.convert_back_block.call(target.send(target_property_name))
        source.send(var_name, source_value)
      end
    end

    source
  end

  # This module add class extension of attr_converter
  module ClassConverter
    def attr_converter(symbol, attr_another_name = nil, convert_bock = nil, convert_back_block = nil)
      # Set default values for nil arguments
      attr_another_name ||= symbol
      convert_bock ||= lambda { |v| v }
      convert_back_block ||= lambda { |v| v }
      @attribute_converter ||= {}

      # Create new ConversionMetadata
      @attribute_converter[symbol] =ConversionMetadata.new(symbol, attr_another_name, convert_bock, convert_back_block)
      attr_accessor symbol
    end
  end

  # Represent conversion data of one property to another
  class ConversionMetadata
    def initialize(source_prop_name, target_prop_name, convert, convert_back)
      @source_property_name = source_prop_name
      @target_property_name = target_prop_name
      @convert_block = convert
      @convert_back_block = convert_back
    end

    attr_accessor :source_property_name
    attr_accessor :target_property_name
    attr_accessor :convert_block
    attr_accessor :convert_back_block
  end
end
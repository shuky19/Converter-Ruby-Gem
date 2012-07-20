# This module helps converting between to instances
# of different classes
module Converter
  def self.included(base)
    base.extend(ClassConverter)
  end

  # Create new Target_Type instance according to Conversion definition
  # @param [Any Class] source instance to copy from
  # @param [class] target_type the result type
  # @return instance of target_type with data from source
  def self.convert(source, target_type, hash = {})
    # Create new target instance
    if(converted_target = hash[source])
      return converted_target
    end

    # Create new target instance
    hash[source] = target = target_type.new

    # Gets source Conversion definition
    conversion_properties = source.class.class_eval { @attribute_converter}

    # update each accessor on the target according to the attr_converters
    source.instance_variables.each do |var|
      var_name = var.to_s.delete('@').to_sym

      # Get the conversion definition for the current accessor if exists
      if convert_property = conversion_properties[var_name]
        target_property_name = convert_property.target_property_name.to_s.concat('=').to_sym

        # Convert from one type to another (by default doesn't do anything)
        if convert_property.convert_block.parameters.count == 1
          target_value = convert_property.convert_block.call(source.send(var_name))
        else
          target_value = convert_property.convert_block.call(source.send(var_name), hash)
        end

        target.send(target_property_name, target_value)
      end
    end

    target
  end

  # Create new source_type instance according to attr_converters
  # @param [Any Class] target instance to copy from
  # @param [class] source_type the result type
  # @return instance of source_type with data from source
  def self.convert_back(target, source_type, hash = {})
    # Create new target instance
    if(converted_source = hash[target])
      return converted_source
    end

    # Create new source instance
    hash[target] = source = source_type.new

    # Gets source Conversion definition
    conversion_properties = source.class.class_eval { @attribute_converter }

    # update each accessor on the target according to the conversion definition
    source.methods.grep(/[a-zA-Z0-9]=$/).each do |var_name|
      var_name_trimmed = var_name.to_s.delete('=').to_sym

      # Get the conversion definition for the current accessor if exists
      if convert_property = conversion_properties[var_name_trimmed]
        target_property_name = convert_property.target_property_name

        # Convert from one type to another (by default doesn't do anything)
        if convert_property.convert_back_block.parameters.count == 1
          source_value = convert_property.convert_back_block.call(target.send(target_property_name))
        else
          source_value = convert_property.convert_back_block.call(target.send(target_property_name), hash)
        end

        source.send(var_name, source_value)
      end
    end

    source
  end

  # This module add class extension of attr_converter
  module ClassConverter
    # Create an attr_accessor and map this attribute as convertable ,
    # this means that this attribute will be converted when calling to Convert/
    # @param [symbol] symbol attribute name
    # @param [symbol] another_name the name of the converted attribute(on the target)
    # @param [block] convert_block block that convert the source data type to the target data type
    # @param [block] convert_back_block block that convert the target data type to the source data type
    def attr_converter(symbol, attr_another_name = nil, convert_block = nil, convert_back_block = nil)
      # Set default values for nil arguments
      attr_another_name ||= symbol
      @attribute_converter ||= {}
      
      if convert_block.class == Symbol
        source_type = convert_block.to_s
        target_type = convert_back_block.to_s
        convert_block = lambda { |s,h| Converter.convert(s, eval(target_type), h)}
        convert_back_block = lambda { |t,h| Converter.convert_back(t, eval(source_type), h)}
      else
        convert_block ||= lambda { |source, hash| source }
        convert_back_block ||= lambda { |target, hash| target }
      end


      # Create new ConversionMetadata
      @attribute_converter[symbol] =ConversionMetadata.new(symbol, attr_another_name, convert_block, convert_back_block)
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
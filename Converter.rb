module Converter
  def self.included(base)
    base.extend(ClassConverter)
  end

  def self.convert(source, target_type)
    target = target_type.new
    conversion_properties = source.class.class_eval { @attribute_converter}

    source.instance_variables.each do |var|
      var_name = var.to_s.delete('@').to_sym
      if conversion_properties.has_key? var_name
        convert_property = conversion_properties[var_name]
        target_property_name = convert_property.target_property_name.to_s.concat('=').to_sym
        target_value = convert_property.convert_block.call(source.send(var_name))
        target.send(target_property_name, target_value)
      end
    end

    target
  end

  def self.convertBack(target, source_type)
    source = source_type.new
    conversion_properties = source.class.class_eval { @attribute_converter }

    source.methods.grep(/[a-zA-Z0-9]=$/).each do |var_name|
      var_name_trimmed = var_name.to_s.delete('=').to_sym
      if conversion_properties.has_key? var_name_trimmed
        convert_property = conversion_properties[var_name_trimmed]
        target_property_name = convert_property.target_property_name
        source_value = convert_property.convert_back_block.call(target.send(target_property_name))
        source.send(var_name, source_value)
      end
    end

    source
  end

  module ClassConverter
    def attr_converter(symbol, attr_another_name = nil, convert_bock = nil, convert_back_block = nil)
      attr_another_name ||= symbol
      convert_bock ||= lambda { |v| v }
      convert_back_block ||= lambda { |v| v }
      @attribute_converter ||= {}
      @attribute_converter[symbol] =AttributeMetadata.new(symbol, attr_another_name, convert_bock, convert_back_block)
      attr_accessor symbol
    end
  end

  class AttributeMetadata
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
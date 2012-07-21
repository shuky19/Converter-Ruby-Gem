# This module helps converting between to instances
# of different classes
module Converter
  def self.included(base)
    base.extend(ClassConverter)
  end
  
  def clone
    convert_to self.class
  end

  def convert_to target_class
    Converter.convert self, target_class
  end

  def copy_to target
      Converter.copy self, target
  end

  # Update the given target object according to the Conversion definition
  # one of the classes (source.class or target.class) should include Converter module
  # @param [Any Class] source instance to copy from
  # @param [Any Class] target the result type
  # @return target with new values
  def self.copy source, target, hash = {}
    # Check if the object has already been converted (Circular pointing)
    if(converted_object = hash[source])
      return converted_object
    end

    # Create new target instance
    hash[source] = target
    
    # Check which of the objects includes Converter module
    # and gets it's Conversion definition
    convertable_object = get_convertable_object source, target
    conversion_metadatas = convertable_object.class.class_eval { @attribute_converter}
    
    if source.class == target.class
      conversion_metadatas = build_conversion_metadata_to_clone conversion_metadatas
    end

    # update each accessor on the target according to the attr_converters
    conversion_metadatas.values.each do |conversion_metadata|
      convert_one_attribute source, target, conversion_metadata, source == convertable_object, hash
    end

    target
  end

  # Create new Target_Type instance according to the Conversion definition
  # one of the classes (source.class or target_type) should include Converter module
  # @param [Any Class] source instance to copy from
  # @param [class] target_type the result type
  # @return instance of target_type with data converted from source
  def self.convert(source, target_type, hash = {})
    copy source, target_type.new, hash
  end
  
  # Create new source.class instance according to the Conversion definition of source
  # source should include Converter module
  # @param [Any Class] source instance to copy from
  # @return instance of source.class with data converted from source
  def self.clone source
    convert source, source.class  
  end

  private

    def self.build_conversion_metadata_to_clone conversion_metadatas
      default_converter = lambda { |source| source }
      new_conversion_metadata = {}
      conversion_metadatas.keys.each do |key| 
        metadata = conversion_metadatas[key]
        new_conversion_metadata[key] = ConversionMetadata.new(metadata.convertable_attribute_name, metadata.convertable_attribute_name, default_converter, default_converter)
      end

      new_conversion_metadata
    end

    def self.get_convertable_object source, target
      if source.class.included_modules.include?(Converter) && target.class.included_modules.include?(Converter)
        if source.class == target.class
          source
        else
          raise ArgumentError.new "Unable to select from two Convertable objects"
        end
      elsif source.class.included_modules.include? Converter
        source
      elsif target.class.included_modules.include? Converter
        target
      else
        raise ArgumentError.new "One of the given classes should include Converter module, classes: #{source.class}, #{target.class}"
      end
    end

    def self.convert_one_attribute source, target, conversion_metadata, is_source_convertable, hash
      source_attribute_name = is_source_convertable ? conversion_metadata.convertable_attribute_name : conversion_metadata.poro_attribute_name
      target_attribute_name = is_source_convertable ? conversion_metadata.poro_attribute_name : conversion_metadata.convertable_attribute_name
      source_attribute_value = source.send(source_attribute_name)
      target_attribute_value = target.send(target_attribute_name)
      target_attribute_name = target_attribute_name.to_s.concat('=').to_sym
      convert_block = conversion_metadata.get_converter(source_attribute_value, target_attribute_value, is_source_convertable)

      # Convert from one type to another (by default doesn't do anything)
      if convert_block.parameters.count == 1
        target_value = convert_block.call(source_attribute_value)
      elsif convert_block.parameters.count == 2
        target_value = convert_block.call(source_attribute_value, hash)
      else
        target_value = convert_block.call(source_attribute_value, target_attribute_value, hash)
      end

      target.send(target_attribute_name, target_value)
    end

  public

  # This module add class extension of attr_converter
  module ClassConverter
    # Create an attr_accessor and map this attribute as convertable ,
    # this means that this attribute will be converted when calling to Convert/
    # @param [symbol] convertable_attribute_name class attribute name
    # @param [symbol] poro_attribute_name the attribute name of a poro class (plain old ruby object)
    # @param [block] convert_block block that convert between the convetable attribute class and the poro attribute class
    # @param [block] convert_back_block block that convert between the poro attribute class and the convetable attribute class
    def attr_converter(convertable_attribute_name, poro_attribute_name = nil, convert_block = nil, convert_back_block = nil)
      # Set default values for nil arguments
      poro_attribute_name ||= convertable_attribute_name
      @attribute_converter ||= {}

      if convert_block.class == Symbol
        convertable_type = convert_block.to_s
        poro_type = convert_back_block.to_s
        convert_block = lambda { |source, hash| Converter.convert(source, eval(poro_type), hash) }
        convert_back_block = lambda { |source, hash| Converter.convert(source, eval(convertable_type), hash) }
      else
        convert_block ||= lambda { |source| source }
        convert_back_block ||= lambda { |source| source }
      end

      # Create new ConversionMetadata
      @attribute_converter[convertable_attribute_name] =ConversionMetadata.new(convertable_attribute_name, poro_attribute_name, convert_block, convert_back_block)
      attr_accessor convertable_attribute_name
    end
  end

  # Represent conversion data of one property to another
  class ConversionMetadata
    def initialize(convertable_attribute_name, poro_attribute_name, convert_from_convertable_block, convert_from_poro_block)
      @convertable_attribute_name = convertable_attribute_name
      @poro_attribute_name = poro_attribute_name
      @convert_from_convertable_block = convert_from_convertable_block
      @convert_from_poro_block = convert_from_poro_block
      @copy_from_convertable_block = lambda { |source, target, hash| Converter.copy(source, target, hash) }
      @copy_from_poro_block = lambda { |source, target, hash| Converter.copy(source, target , hash) }
    end

    attr_accessor :convertable_attribute_name
    attr_accessor :poro_attribute_name
    attr_accessor :convert_from_convertable_block
    attr_accessor :convert_from_poro_block
    attr_accessor :copy_from_convertable_block
    attr_accessor :copy_from_poro_block

    def get_converter source_attribute_value, target_old_attribute_value, is_source_convertable
      # Check if one of the attributes is Convertable
      has_convertable_object = source_attribute_value.class.included_modules.include?(Converter) || target_old_attribute_value.class.included_modules.include?(Converter)

      # Copy between inner attribute only if they are convertale and exists
      if has_convertable_object && target_old_attribute_value
        if is_source_convertable
          copy_from_convertable_block
        else
          copy_from_poro_block
        end
      elsif is_source_convertable
        convert_from_convertable_block
      else
        convert_from_poro_block
      end
    end
  end
end
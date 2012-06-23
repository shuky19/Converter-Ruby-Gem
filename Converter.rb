module Converter
	def self.included(base)
		base.extend(ClassConverter)
	end

	def self.convert(source, targetType)
		target = targetType.new
		source.instance_variables.each do |var|
			varName = var.to_s.delete('@').to_sym
			converter = source.class.class_eval { @attribute_converter }
			if converter.has_key? varName
				targetPropertyName = converter[varName][0] || varName
				targetPropertyName = targetPropertyName.to_s.concat('=').to_sym
				targetValue = converter[varName][1] ?
								converter[varName][1].call(source.send(varName)) :
								source.send(varName)

				target.send(targetPropertyName, targetValue)
			end
		end

		target
	end

	def self.convertBack(target, sourceType)
		source = sourceType.new
		source.methods.grep(/[a-zA-Z0-9]=$/).each do |varName|
			varNameTrimmed = varName.to_s.delete('=').to_sym
			converter = source.class.class_eval { @attribute_converter }
			if converter.has_key? varNameTrimmed
				targetPropertyName = converter[varNameTrimmed][0] || varNameTrimmed
				sourceValue = converter[varNameTrimmed][2] ?
								converter[varNameTrimmed][2].call(target.send(targetPropertyName)) :
								target.send(targetPropertyName)
				source.send(varName, sourceValue)
			end
		end

		source
	end

	module ClassConverter
		def attr_converter(symbol, attr_another_name = nil, converterBlock = nil, converterBackBlock = nil)
		      @attribute_converter ||= {}
		      @attribute_converter[symbol] = [attr_another_name, converterBlock, converterBackBlock]
		      class_eval( "def #{symbol}() @#{symbol}; end" )
		      class_eval( "def #{symbol}=(val) @#{symbol} = val; end" )
		end
	end
end
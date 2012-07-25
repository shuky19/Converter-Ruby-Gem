require_relative '..\\lib\\Converter.rb'

class Person
	def initialize
		yield self unless !block_given?
	end

	attr_accessor :first_name
	attr_accessor :last_name
	attr_accessor :cash
	attr_accessor :id
	attr_accessor :dog
end

class Dog
	def initialize
		yield self unless !block_given?
	end

	attr_accessor :age
	attr_accessor :name
	attr_accessor :human
    attr_accessor :food
end

class Food
    def initialize
		yield self unless !block_given?
	end

	attr_accessor :name
    attr_accessor :is_junk_food
end

class DogDto
	include Converter

	def initialize
		yield self unless !block_given?
	end

	attr_converter :age
	attr_converter :name
	attr_converter :person, :human, :PersonDto, :Person
    attr_converter :food, :food, :FoodDto, :Food
end

class PersonDto
	include Converter

	def initialize
		yield self unless !block_given?
	end

	attr_accessor :update_time
	attr_converter :first_name
	attr_converter :last_name
	attr_converter :old, :age
	attr_converter :money, :cash, lambda { |m| m.to_f }, lambda { |c| c.to_int }
	attr_converter :pappy, :dog, :DogDto, :Dog
end

class FoodDto
    include Converter

	def initialize
		yield self unless !block_given?
	end
    
    attr_converter :name
    attr_converter :is_junk_food
end
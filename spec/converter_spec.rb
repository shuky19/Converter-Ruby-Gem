require 'date'
require_relative './spec_helper.rb'

describe PersonDto do
	it "should respond to convert" do
		PersonDto.new.should respond_to :convert_to
	end

	describe "#convert_to" do
		before :all do
			@person_dto = PersonDto.new do |p|
				p.first_name = "Shuky"
				p.last_name = "Chen"
				p.old = 21
				p.money = 15
				p.update_time = DateTime.now
				p.pappy = DogDto.new do |d|
					d.age = 3
					d.name = "rocky"
					d.person = p
				end
			end

			@person = @person_dto.convert_to Person
		end	

		it "Should create new Person" do
			@person.should be_an_instance_of Person
		end

		it "Should have the same values" do
			@person.first_name.should equal @person_dto.first_name
			@person.last_name.should equal @person_dto.last_name
			@person.age.should equal @person_dto.old
		end

		it "Should convert data types" do
			@person_dto.money.class.should_not equal @person.cash.class
		end

		it "Should not set unmapped attributes" do
			@person.id.should be_nil
			@person.respond_to?(:update_time).should be_false
		end

		it "should convert inner objects" do
			@person.dog.should_not be_nil
			@person.dog.name.should equal @person_dto.pappy.name
			@person.dog.age.should equal @person_dto.pappy.age
		end

		it "should have circurlar pointing" do
			@person.dog.human.should equal(@person)
		end
	end
end

describe Converter do

	describe "#convert" do
		before :all do
			@person = Person.new do |p|
				p.cash = 15.0
				p.first_name = "Shuky"
				p.last_name = "Chen"
				p.age = 21
				p.id = 1
				p.dog = Dog.new do |d|
					d.age = 3
					d.name = "rocky"
					d.human = p
				end
			end

			@person_dto = Converter.convert(@person, PersonDto)
		end	

		it "Should create new PersonDto" do
			@person_dto.should be_an_instance_of PersonDto
		end

		it "Should have the same values" do
			@person_dto.first_name.should equal @person_dto.first_name
			@person_dto.last_name.should equal @person.last_name
			@person_dto.old.should equal @person.age
		end

		it "Should convert data types" do
			@person_dto.money.class.should_not equal @person.cash.class
		end

		it "Should not set unmapped attributes" do
			@person_dto.update_time.should be_nil
			@person_dto.respond_to?(:id).should be_false
		end

		it "should convert inner objects" do
			@person_dto.pappy.should_not be_nil
			@person_dto.pappy.name.should equal @person.dog.name
			@person_dto.pappy.age.should equal @person.dog.age
		end

		it "should have circurlar pointing" do
			@person_dto.pappy.person.should equal @person_dto
		end
	end
end
require 'date'
require_relative './spec_helper.rb'

describe PersonDto do
	it "should respond to convert_to" do
		PersonDto.new.should respond_to :convert_to
	end

	it "should respond to copy_to" do
		PersonDto.new.should respond_to :copy_to
	end

	it "should respond to clone" do
		PersonDto.new.should respond_to :clone
	end

	describe "#copy_to" do
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

			@person = Person.new
			@person.first_name = "not Shuky"
			@person.last_name = "not Chen"
			@person.age = 5
			@person.id = 3
			@person.cash = 3.02
			@person.dog = Dog.new
			@person.dog.age = 2
			@person.dog.name = "not rocky"
			@person.dog.human = @person
			
			@person_dto.copy_to @person
		end

		it "should copy all values from personDto" do
			@person.first_name.should equal @person_dto.first_name
			@person.last_name.should equal @person_dto.last_name
			@person.age.should equal @person_dto.old
			@person.cash.to_int.should eql @person_dto.money
		end

		it "should have the same id" do
			person  = Person.new
			person.id = 1
			lambda { @person_dto.copy_to person}.should_not change person, :id
		end

		it "should not override inner objects" do
			person = Person.new
			person.dog = Dog.new
			person.dog.human = person
			lambda { @person_dto.copy_to person}.should_not change person, :dog
			person.dog.human.should equal(person)
		end

		it "should copy the inner object too" do
			@person.dog.should_not be_nil
			@person.dog.name.should equal @person_dto.pappy.name
			@person.dog.age.should equal @person_dto.pappy.age
		end

		it "should have circurlar pointing" do
			@person.dog.human.should equal(@person)
		end

		it "should be able to copy itself" do
			person_dto = PersonDto.new
			@person_dto.copy_to person_dto
			person_dto.first_name.should equal @person_dto.first_name
			person_dto.last_name.should equal @person_dto.last_name
			person_dto.old.should equal @person_dto.old
			person_dto.money.should equal @person_dto.money
			person_dto.pappy.should equal @person_dto.pappy
			person_dto.update_time.should_not equal @person_dto.update_time
		end
	end

	describe "#clone" do
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

			@person_dto2 = @person_dto.clone
		end

		it "should clone itself" do
			@person_dto2.first_name.should equal @person_dto.first_name
			@person_dto2.last_name.should equal @person_dto.last_name
			@person_dto2.old.should equal @person_dto.old
			@person_dto2.money.should equal @person_dto.money
			@person_dto2.pappy.should equal @person_dto.pappy
			@person_dto2.update_time.should_not equal @person_dto.update_time
		end
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
	
	describe "#copy_to" do
		before :all do
			@person = Person.new do |p|
				p.first_name = "Shuky"
				p.last_name = "Chen"
				p.age = 21
				p.cash = 15.0
				p.id = 5
				p.dog = Dog.new do |d|
					d.age = 3
					d.name = "rocky"
					d.human = p
				end
			end

			@person_dto = PersonDto.new
			Converter.copy @person, @person_dto
		end

		it "should copy all values from personDto" do
			@person_dto.first_name.should equal @person.first_name
			@person_dto.last_name.should equal @person.last_name
			@person_dto.old.should equal @person.age
			@person_dto.money.should eql @person.cash.to_int
		end

		it "should have the same id" do
			person_dto = PersonDto.new
			person_dto.update_time = DateTime.now
			lambda { Converter.copy @person, person_dto}.should_not change person_dto, :update_time
		end

		it "should not override inner objects" do
			person_dto = PersonDto.new
			person_dto.pappy = DogDto.new
			person_dto.pappy.person = person_dto
			lambda { Converter.copy @person, person_dto}.should_not change person_dto, :pappy
			person_dto.pappy.person.should equal(person_dto)
		end

		it "should copy the inner object too" do
			@person_dto.pappy.should_not be_nil
			@person_dto.pappy.name.should equal @person.dog.name
			@person_dto.pappy.age.should equal @person.dog.age
		end

		it "should have circurlar pointing" do
			@person_dto.pappy.person.should equal(@person_dto)
		end
	end

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

	describe "#clone" do
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

			@person_dto2 = Converter.clone @person_dto
		end

		it "should clone itself" do
			@person_dto2.first_name.should equal @person_dto.first_name
			@person_dto2.last_name.should equal @person_dto.last_name
			@person_dto2.old.should equal @person_dto.old
			@person_dto2.money.should equal @person_dto.money
			@person_dto2.pappy.should equal @person_dto.pappy
			@person_dto2.update_time.should_not equal @person_dto.update_time
		end
	end
end
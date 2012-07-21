Converter gem
============

Latest updates
---------------

1. Merge convert and convert_back to one method (convert)
2. Add default lambda creation for inner conversion (converting the inner attribute using the Converter, see down the page)
3. Add convert_to instance method to class that includes Converter module
4. Add copy_to instance method to class that includes Converter module
5. Add copy method to Converter module
6. Add clone instance method to class that includes Converter module
7. Add clone method to Converter module

Getting started
---------------

The first class you create should bea  normal class like this:

    class Person
      attr_accessor :fname
      attr_accessor :last_name
      attr_accessor :country_name
      attr_accessor :remark
      attr_accessor :city_name
      attr_accessor :phone_number
      attr_accessor :cash_as_int
      attr_accessor :onlyPersonAttribute
    end

In the second class you should use attr_converter instead of attr_accessor,
this allows Converter to recognize which attributes
it should convert.

you can specify various of properties with "attr_converter":

1. The target accessor name(if it's different from the source accessor name)

2. A lambda used to convert data from the source to the target(if they are not of the same class)

3. A lambda used to convert data from the target to the source(if they are not of the same class)

Here an example of PersonDto:

    class PersonDto
     include Converter

      # This is a declaration of attr_converter that describe "first_name" accessor of PersonDTO class
      #  and maps it to "fname" accessor of Person class
      attr_converter :first_name, :fname

     # The declarations in this section describe an accessor of PersonDTO class
     #  and maps it to accessor with the same name on Person class
      attr_converter :last_name
      attr_converter :country_name
      attr_converter :remark
      attr_converter :city_name
      attr_converter :phone_number

      # This is a declaration of attr_converter that describe "money_as_string" accessor
      # and maps it to "cash_as_int" access, but also specify converter to convert this data types.
      attr_converter :money_as_string, :cash_as_int, lambda { |v| v.to_f.to_int}, lambda { |v| v.to_s }
      attr_accessor :onlyPersonDtoAttribute
    end

If we will create instance of PersonDTO:

        p_dto = PersonDto.new
        p_dto.first_name = 'Robert'
        p_dto.last_name = 'De niro'
        p_dto.country_name = 'Lala land'
        p_dto.city_name = 'a city name'
        p_dto.remark = 'good actor'
        p_dto.phone_number = '65432165498'
        p_dto.money_as_string = '321654987'
        p_dto.onlyPersonDtoAttribute = 'lalala'

Result:

     => [#PersonDto:0x2d3cac8 @first_name="Robert", @last_name="De niro", @country_name="Lala land",
     @city_name="a city name", @remark="good actor", @phone_number="65432165498",
     @money_as_string="321654987", @onlyPersonDtoAttribute="lalala"}

we could now convert it to Person:

    p = p_dto.convert_to Person

Result:

     => [#Person:0x2d3c9d8 @fname="Robert", @last_name="De niro", @country_name="Lala land",
      @city_name="a city name", @remark="good actor", @phone_number="65432165498",
      @cash_as_int=321654987, @onlyPersonAttribute="asdasdasd"}

To Convert from Preson to PersonDTO user ConvertBack:

    p_dto = Converter.convert(p, PersonDto)

Result:

    => [#PersonDto:0x2d3c4e
             0 @first_name="Robert", @last_name="De niro", @country_name="Lala land", @city_name="a city name",
             @remark="good actor", @phone_number="65432165498", @money_as_string="321654987"}


Getting Deeper
-------------------

We can take Converter module into extreme by converting
entire graph of objects.

Lets create a Dog class:

    class Dog
      attr_accessor :name
      attr_accessor :age
    end

and extend Person class to include dog:

    class Person
        attr_accessor dog
    end

now we should do the same with PersonDto:

    class dogDTO
        attr_converter :dog_name, :name
         attr_converter :age
    end

    class PersonDTO
        # This assign the types of dogDto to DogDto and dog to Dog
        # and it will allow the converter to convert those type automatically!
        attr_converter :dogDTO, :dog, :DogDto, :Dog
    end

Lets Convert them!

     p_dto = PersonDto.new
     p_dto.first_name = 'Robert'
     p_dto.last_name = 'De niro'
     p_dto.country_name = 'Lala land'
     p_dto.city_name = 'a city name'
     p_dto.remark = 'good actor'
     p_dto.phone_number = '65432165498'
     p_dto.money_as_string = '321654987'
     p_dto.onlyPersonDtoAttribute = 'lalala'
     p_dto.dogDTO = DogDTO.new
     p_dto.dogDTOd.dog_name = "papi"
     p_dto.dogDTOd.age=7

Result:

     => [#PersonDto:0x2be8fb8 @first_name="Robert", @last_name="De niro", @country_name="Lala land",
                                                       @city_name="a city name", @remark="good actor", @phone_number="65432165498",
                                                       @money_as_string="321654987", @onlyPersonDtoAttribute="lalala",
                                                       @dogDTO=#DogDTO:0x2be8e98 @age=7, @dog_name="papi"}

we could now convert it to Person:

    p = p_dto.convert_to Person)

Result:

     => {#Person:0x2be8e68 @fname="Robert", @last_name="De niro", @country_name="Lala land", @city_name="a city name",
                                                 @remark="good actor", @phone_number="65432165498", @cash_as_int=321654987,
                                                 @onlyPersonAttribute="asdasdasd", @dog=#Dog:0x2be8880 @age=7, @name="papi"}


To Convert from Preson to PersonDTO user ConvertBack:

    p_dto = Converter.convert(p, PersonDto)

Result:

    => [#PersonDto:0x2be86e8 @first_name="Robert", @last_name="De niro", @country_name="Lala land",
                                                      @city_name="a city name", @remark="good actor", @phone_number="65432165498",
                                                      @money_as_string="321654987", @dog=#DogDTO:0x2bace98 @age=7, @dog_name="papi"}


What about Circular pointing?
--------------

Lets say dog has accessor to his person:

    class dogDTO
          attr_converter :dog_name, :name
          attr_converter :age
          attr_converter :personDto
    end

    class dog
          attr_converter :name, :dog_name
          attr_converter :age
          attr_converter :person
    end

now what will happend? well Converter has a support for it,
the result of the conversion will do the expected:

      p = p_dto.convert_to Person    

Result:

       => {#Person:0x2be8e68 @fname="Robert", @last_name="De niro", @country_name="Lala land", @city_name="a city name",
                                                     @remark="good actor", @phone_number="65432165498", @cash_as_int=321654987,
                                                     @onlyPersonAttribute="asdasdasd", @dog=#Dog:0x2be8880 @age=7, @name="papi, @person=#Person:0x2be8e68 ..."}

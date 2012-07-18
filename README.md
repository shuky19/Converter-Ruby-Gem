Converter gem
==========

Getting started
---------------

The first class you create should be normal class like this::

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

    p = Converter.convert(p_dto, Person)

Result:
 => [#Person:0x2d3c9d8 @fname="Robert", @last_name="De niro", @country_name="Lala land",
  @city_name="a city name", @remark="good actor", @phone_number="65432165498",
  @cash_as_int=321654987, @onlyPersonAttribute="asdasdasd"}

To Convert from Preson to PersonDTO user ConvertBack:

    p_dto = Converter.convertBack(p, PersonDto)

Result:
=> [#PersonDto:0x2d3c4e
         0 @first_name="Robert", @last_name="De niro", @country_name="Lala land", @city_name="a city name",
         @remark="good actor", @phone_number="65432165498", @money_as_string="321654987"}
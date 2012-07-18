Converter gem
==========

Getting started
---------------

Create two type you would like to convert between them.

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

    class PersonDto
     include Converter

      attr_converter :first_name, :fname
      attr_converter :last_name
      attr_converter :country_name
      attr_converter :remark
      attr_converter :city_name
      attr_converter :phone_number
      attr_converter :money_as_string, :cash_as_int, lambda { |v| v.to_f.to_int}, lambda { |v| v.to_s }
      attr_accessor :onlyPersonDtoAttribute
    end

Now create instance of PersonDTO:
    p_dto = PersonDto.new
    p_dto.first_name = 'Robert'
    p_dto.last_name = 'De niro'
    p_dto.country_name = 'Lala land'
    p_dto.city_name = 'a city name'
    p_dto.remark = 'good actor'
    p_dto.phone_number = '65432165498'
    p_dto.money_as_string = '321654987'
    p_dto.onlyPersonDtoAttribute = 'lalala'

To convert from PersonDTO to Person user ConvertMethods:
    p = Converter.convert(p_dto, Person)

To Convert from Preson to PersonDTO user ConvertBack:
    p_dto = Converter.convertBack(p, PersonDto)
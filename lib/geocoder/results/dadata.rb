require 'geocoder/results/base'

module Geocoder::Result
  class Dadata < Base

    def initialize(data)
      super
      @full_address = data["value"]
      @data = data["data"]
    end

    def coordinates
      [@data['geo_lat'].to_f, @data['geo_lon'].to_f]
    end

    def street_name
      @data['street']
    end

    def street
      @data['street_with_type']
    end

    def address(format = :full)
      @full_address
    end

    def city
      @data['city_with_type']
    end

    def country
      @data['country']
    end

    def country_code
      @data['country_iso_code']
    end

    def state
      @data['area']
    end

    def state_code
      @data['area_fias_id']
    end

    def postal_code
      @data['postal_code']
    end

    def house
      @data["house"]
    end
  end
end

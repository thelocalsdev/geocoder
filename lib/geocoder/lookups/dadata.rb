require 'geocoder/lookups/base'
require "geocoder/results/dadata"

module Geocoder::Lookup
  class Dadata < Base

    def name
      "Dadata"
    end

    def map_link_url(coordinates)
      "https://suggestions.dadata.ru/suggestions/api/4_1/rs/geolocate/address?lat=#{coordinates[0]}&lon=#{coordinates[1]}"
    end

    def supported_protocols
      [:https]
    end

    private # ---------------------------------------------------------------

    def base_query_url(query)
      base = "#{protocol}://suggestions.dadata.ru/suggestions/api/4_1/rs"
      if query.reverse_geocode?
        "#{base}/geolocate/address?"
      else
        "#{base}/suggest/address?"
      end
    end

    def make_api_request(query)
      uri = URI.parse(query_url(query))
      Geocoder.log(:debug, "Geocoder: HTTP request being made for #{uri.to_s}")
      http_client.start(uri.host, uri.port, use_ssl: use_ssl?, open_timeout: configuration.timeout, read_timeout: configuration.timeout) do |client|
        configure_ssl!(client) if use_ssl?
        req = Net::HTTP::Post.new(uri.request_uri, http_headers)
        req.body = request_body(query)
        client.request(req)
      end
    rescue Timeout::Error
      raise Geocoder::LookupTimeout
    rescue Errno::EHOSTUNREACH, Errno::ETIMEDOUT, Errno::ENETUNREACH, Errno::ECONNRESET
      raise Geocoder::NetworkError
    end

    def results(query)
      return [] unless doc = fetch_data(query)
      
      if doc['family']
        if doc["message"] == "An Authentication object was not found in the SecurityContext"
          raise_error(Geocoder::InvalidApiKey) || Geocoder.log(:warn, "Invalid API key.")
        else
          Geocoder.log(:warn, "DADATA Geocoding API error: #{doc['reason']} (#{doc['message']}).")
        end
        return []
      end
      if doc = doc['suggestions']
        return doc
      else
        Geocoder.log(:warn, "DADATA Geocoding API error: unexpected response format.")
        return []
      end
    end

    def http_headers
      {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': "Token #{configuration.api_key}"
      }
    end

    def request_body(query)
      params = {}
      if query.reverse_geocode?
        params[:lat] = query.coordinates.first
        params[:lon] = query.coordinates.last
      else
        params[:query] = query.sanitized_text
      end

      params[:locations] = query.options[:regions].map{ |id| {"region_fias_id": id} } if query.options[:regions]
      params[:locations_boost] = query.options[:locations_boost].map{ |id| {"kladr_id": id} } if query.options[:locations_boost]
      params.to_json
    end
  end
end

require 'rest_client'
require 'builder'
require_relative 'error'

module Bosh4r
  module Utils
    def build_xml(options = {}, &callback)
      builder = Builder::XmlMarkup.new
      params = {
        :xmlns => 'http://jabber.org/protocol/httpbind',
        'xmlns:xmpp' => 'urn:xmpp:xbosh'
      }.merge(options)
      if block_given?
        builder.body(params) { |body|
          yield(body)
        }
      else
        builder.body(params)
      end
    end

    # Sends bosh request
    def send_bosh_request(url, params)
      resource = RestClient::Resource.new(url, rest_client_options)
      response = resource.post(params, rest_client_headers)
      parsed_response = REXML::Document.new(response)
      terminate = (REXML::XPath.first parsed_response, '/body').attribute('type') == 'terminate'
      raise Bosh4r::Error.new 'Check your BOSH endpoint' if terminate
      parsed_response
    rescue => e
      raise Bosh4r::Error.new(e.message)
    end

    def rest_client_options
      {}
    end

    def rest_client_headers
      {
          'Content-Type' => 'text/xml; charset=utf-8',
          'Accept' => 'text/xml'
      }
    end
  end
end
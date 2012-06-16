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
      response = RestClient.post(url, params, {
        'Content-Type' => 'text/xml; charset=utf-8',
        'Accept' => 'text/xml'
      })
      p response
      parsed_response = REXML::Document.new(response)
      terminate = (REXML::XPath.first parsed_response, '/body').attribute('type') == 'terminate'
      throw Bosh4r::Error.new 'Check your BOSH endpoint' if terminate
      parsed_response
    rescue => e
      throw Bosh4r::Error.new(e.message)
    end
  end
end

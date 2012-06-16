# Middleware that initializes a BOSH session with an XMPP server
# and returns the session identifier and request identifier.
#
# Session identifier and request identifier are typically used to
# attach another client side session with the XMPP server.
# Ex: http://strophe.im/strophejs/doc/1.0.2/files2/strophe-js.html#Strophe.Connection.attach
#
# Author        :  Ganesh Gunasegaran <me@itsgg.com>
# Last Modified :  June 16, 2012
# Website       :  https://github.com/itsgg/bosh_session
# Copyright     :  MIT License

require 'rexml/document'
require 'rexml/xpath'
require 'base64'
require_relative 'error'
require_relative 'utils'

module Bosh4r
  class Session
    include Bosh4r::Utils

    attr_reader :sid, :rid

    def initialize(jabber_id, password, options = {})
      split_jabber_id = jabber_id.split('/')
      bare_jabber_id = split_jabber_id.first
      resource_name = split_jabber_id.last if split_jabber_id.size > 1

      @jabber_id = bare_jabber_id
      @password = password
      @host = @jabber_id.split('@').last

      @bosh_url = options[:bosh_url] || 'http://localhost:5280/http-bind'
      @timeout = options[:timeout] || 5     # Network timeout
      @wait = options[:wait] || 5           # Longest time the connection manager is allowed to wait before responding
      @hold = options[:hold] || 1           # Number of connections that the connection manager can hold
      @version = options[:version] || '1.0' # BOSH protocol version
      @rid = rand(1000)
      @resource_name = resource_name.nil? ? "bosh_#{Time.now.to_i.to_s(36)}" : resource_name
      connect
    end

    def connected?
      @connected
    end

    protected
    def connect
      throw Bosh4r::Error.new('Failed to initiate BOSH session') unless initiate_session
      throw Bosh4r::Error.new('Failed to authenticate BOSH session') unless authenticate_session
      throw Bosh4r::Error.new('Failed to restart BOSH stream') unless restart_stream
      throw Bosh4r::Error.new('Failed to bind resource') unless bind_resource
      throw Bosh4r::Error.new('Failed to request BOSH session') unless request_session
      @connected = true
      self
    end

    def initiate_session
      params = build_xml(:wait => @wait, :to => @host, :hold => @hold,
                         'xmpp:version' => @version, :rid => @rid += 1)
      parsed_response = send_bosh_request(@bosh_url, params)
      sid_node = (REXML::XPath.first parsed_response, '/body').attribute('sid')
      @sid = sid_node && sid_node.value()
    end

    def authenticate_session
      # Use SASL with base64 encoding
      username = @jabber_id.split('@').first
      # admin@imac.local
      # admin
      # password
      auth_str = "#{@jabber_id}\u0000#{username}\u0000#{@password}"
      auth_key = Base64.encode64(auth_str).gsub(/\s/, '')
      params = build_xml(:sid => @sid, 'xmpp:version' => @version, :rid => @rid += 1) do |body|
        body.auth(auth_key, :xmlns => 'urn:ietf:params:xml:ns:xmpp-sasl', :mechanism => 'PLAIN')
      end
      REXML::XPath.first send_bosh_request(@bosh_url, params), '/body/success'
    end

    def restart_stream
      params = build_xml(:sid => @sid, 'xmpp:restart' => true,
                         'xmpp:version' => @version, :rid => @rid += 1)
      REXML::XPath.first send_bosh_request(@bosh_url, params), '/body/stream:features'
    end

    def bind_resource
      params = build_xml(:sid => @sid, 'xmpp:version' => @version, :rid => @rid += 1) do |body|
        body.iq(:id => "bind_#{rand(1000000)}", :type => 'set', :xmlns => "jabber:client") do |iq|
          iq.bind(:xmlns => 'urn:ietf:params:xml:ns:xmpp-bind') do |bind|
            bind.resource(@resource_name)
          end
        end
      end
      REXML::XPath.first send_bosh_request(@bosh_url, params), '//jid'
    end

    def request_session
      params = build_xml(:sid => @sid, 'xmpp:version' => @version, :rid => @rid += 1) do |body|
        body.iq(:id => "session_#{rand(1000000)}", :type => 'set', :xmlns => 'jabber:client') do |iq|
          iq.session(:xmlns => 'urn:ietf:params:xml:ns:xmpp-session')
        end
      end
      REXML::XPath.first send_bosh_request(@bosh_url, params), '/body/iq/session'
    end
  end
end

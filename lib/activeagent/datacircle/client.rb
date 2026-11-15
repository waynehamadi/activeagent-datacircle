# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

module ActiveAgent
  module Datacircle
    # What Datacircle's API answered when it gave no data (its HTTP status in #status), or why it could not be reached.
    class Error < StandardError
      attr_reader :status

      def initialize(message = nil, status: nil)
        super(message)
        @status = status
      end
    end

    # One HTTPS GET to Datacircle's open API, with no key: its answer as a Hash or an Array.
    class Client
      BASE = 'https://api.datacircle.dev/v1'

      def get(path, params = {})
        uri = URI("#{BASE}#{path}")
        query = params.reject { |_, value| value.nil? || value == '' }
        uri.query = URI.encode_www_form(query) unless query.empty?
        2.times do |attempt|
          response = request(uri)
          return JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)

          if response.code == '429' && attempt.zero?
            sleep(wait(response))
            next
          end
          raise Error.new("Datacircle's API answered #{response.code}: #{words(response.body)}", status: response.code.to_i)
        end
        raise Error, "Datacircle's API answered 429 twice: wait a minute and call again"
      end

      private

      def request(uri)
        Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 15, read_timeout: 30) do |http|
          http.get(uri.request_uri, 'Accept' => 'application/json', 'User-Agent' => "activeagent-datacircle/#{VERSION}")
        end
      rescue SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError, Net::HTTPBadResponse => e
        raise Error, "Datacircle's API could not be reached: #{e.message}"
      end

      # The API asks to wait in Retry-After: its seconds, a minute at most.
      def wait(response)
        Integer(response['Retry-After'] || 30).clamp(1, 60)
      rescue ArgumentError
        30
      end

      # The API's error, with the slugs it knows when it gives them.
      def words(body)
        parsed = JSON.parse(body)
        return body[0, 3000] unless parsed.is_a?(Hash) && parsed['error']
        return parsed['error'] unless parsed['slugs']

        "#{parsed['error']}; the slugs: #{Array(parsed['slugs']).join(', ')}"[0, 3000]
      rescue JSON::ParserError
        body.to_s[0, 3000]
      end
    end
  end
end

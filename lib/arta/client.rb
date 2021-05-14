# frozen_string_literal: true

class ARTAError < StandardError; end

module ARTA
  class Client
    API_KEY = Rails.application.config_for(:arta)['arta_api_key']
    API_ROOT_URL = Rails.application.config_for(:arta)['arta_api_root_url']
    DEFAULT_TIMEOUT = 5

    class << self
      def post(url:, params: {})
        response = connection.post(url, params.to_json)
        process(response)
      end

      private

      def process(response)
        # TODO: We should def handle 500s from ARTA here
        # eg: unhandled exception: status: 500, body: {}

        # TODO: 422s that have an error message maybe bubble them up somewhere
        # eg: {:errors=>{:"objects/0"=>["Required property height was not present."]}}
        raise ARTAError, "Couldn't perform request! status: #{response.status}. Message: #{response.body[:errors]}" unless response.success?

        response.body
      end

      def headers
        {
          'Content-Type' => 'application/json',
          'Authorization' => "ARTA_APIKey #{API_KEY}"
        }
      end

      def timeout_defaults
        { timeout: DEFAULT_TIMEOUT, open_timeout: DEFAULT_TIMEOUT }
      end

      def connection
        Faraday.new(
          API_ROOT_URL,
          request: timeout_defaults,
          headers: headers
        ) do |conn|
          conn.response(:json, parser_options: { symbolize_names: true })
        end
      end
    end
  end
end

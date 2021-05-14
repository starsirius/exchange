module ARTA
  class ShippingService
    class << self
      EXPIRATION_WINDOW = 14.days

      def generate_shipping_quotes(line_item:)
        artwork = Gravity.get_artwork(line_item.artwork_id)
        return unless artwork

        data = ARTA::Quote.create(
          artwork: artwork,
          list_price_cents: line_item.list_price_cents
        )

        shipping_quote_request = ShippingQuoteRequest.new(
          line_item_id: line_item.id,
          external_id: data[:id],
          internal_reference: data[:internal_reference],
          public_reference: data[:public_reference],
          quoted_at: data[:created_at],
          expires_at: convert_to_expires_at(data[:created_at]),
          response_payload: data
        )

        shipping_quote_request.shipping_quotes << data[:quotes].map do |quote|
          ShippingQuote.new(
            tier: quote[:quote_type],
            name: parse_name(quote),
            external_id: quote[:id],
            price_cents: convert_total_to_cents(quote[:total]),
            price_currency: quote[:total_currency]
          )
        end

        shipping_quote_request.save!
      end

      private

      def parse_name(quote)
        return if quote[:included_services].empty?

        quote[:included_services].map { |service| service[:name] if service[:subtype] == 'parcel' }.join
      end

      # TODO: Will need to change when supporting non USD currencies
      def convert_total_to_cents(total)
        return unless total

        (Float(total) * 100).round
      end

      def convert_to_expires_at(created_at_timestamp)
        created_at_timestamp.to_datetime + EXPIRATION_WINDOW
      end
    end
  end
end

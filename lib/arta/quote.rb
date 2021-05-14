# frozen_string_literal: true

module ARTA
  class Quote
    FRAMED_CATEGORY_MAP = {
      "Photography": 'photograph_framed',
      "Painting": 'painting_framed',
      "Print": 'work_on_paper_framed',
      "Drawing, Collage or other Work on Paper": 'work_on_paper_framed',
      "Mixed Media": 'mixed_media_framed'
    }.freeze

    UNFRAMED_CATEGORY_MAP = {
      "Photography": 'photograph_unframed',
      "Painting": 'painting_unframed',
      "Print": 'work_on_paper_unframed',
      "Drawing, Collage or other Work on Paper": 'work_on_paper_unframed',
      "Mixed Media": 'mixed_media_unframed',
      "Sculpture": 'scuplture'
    }.freeze

    class << self
      def create(artwork:, list_price_cents:)
        params = formatted_post_params(artwork, list_price_cents)
        ARTA::Client.post(url: '/requests', params: params)
      end

      def formatted_post_params(artwork, list_price_cents)
        {
          request: {
            destination: buyer_info,
            objects: [
              artwork_details(artwork, list_price_cents)
            ],
            origin: artwork_origin_location_and_contact_info
          }
        }
      end

      private

      def artwork_details(artwork, list_price_cents)
        {
          subtype: format_artwork_type(artwork[:category], artwork[:framed]),
          unit_of_measurement: 'cm',
          height: artwork[:height_cm] || artwork[:diameter_cm],
          width: artwork[:width_cm] || artwork[:diameter_cm],
          depth: artwork[:depth_cm],
          value: convert_to_dollars(list_price_cents),
          value_currency: artwork[:price_currency]
        }.compact
      end

      def format_artwork_type(artwork_category, framed)
        return FRAMED_CATEGORY_MAP[artwork_category.to_sym] if framed

        UNFRAMED_CATEGORY_MAP[artwork_category.to_sym]
      end

      # TODO: Will need to change when supporting non USD currencies
      def convert_to_dollars(list_price_cents)
        return unless list_price_cents

        Float(list_price_cents) / 100
      end

      def buyer_info
        {
          title: 'Collector Molly',
          address_line_1: '332 Prospect St',
          city: 'Niagara Falls',
          region: 'NY',
          country: 'US',
          postal_code: '14303',
          contacts: [
            {
              name: 'Collector Molly',
              email_address: 'test@email.com',
              phone_number: '4517777777'
            }
          ]
        }
      end

      def artwork_origin_location_and_contact_info
        {
          title: 'Hello Gallery',
          address_line_1: '401 Broadway',
          city: 'New York',
          region: 'NY',
          country: 'US',
          postal_code: '10013',
          contacts: [
            {
              name: 'Artsy Partner',
              email_address: 'partner@test.com',
              phone_number: '6313667777'
            }
          ]
        }
      end
    end
  end
end

require 'rails_helper'
require 'support/gravity_helper'

describe ShippingCalculator, type: :services do
  let(:artwork_in_italy_attrs) do
    {
      _id: 'a-1',
      domestic_shipping_fee_cents: 100_00,
      international_shipping_fee_cents: 500_00,
      location: {
        country: 'IT',
        city: 'Milan',
        state: 'Lombardy'
      },
      eu_shipping_origin: true
    }
  end
  let(:continental_us_artwork_attrs) do
    {
      _id: 'a-2',
      domestic_shipping_fee_cents: 100_00,
      international_shipping_fee_cents: 500_00,
      location: {
        country: 'US',
        city: 'Brooklyn',
        state: 'NY'
      },
      eu_shipping_origin: false
    }
  end
  let(:missing_artwork_location_attrs) do
    {
      _id: 'a-3',
      domestic_shipping_fee_cents: 100_00,
      international_shipping_fee_cents: 500_00,
      location: nil
    }
  end

  let(:artwork) { gravity_v1_artwork }
  let(:continental_us_artwork) { gravity_v1_artwork(continental_us_artwork_attrs) }
  let(:artwork_in_italy) { gravity_v1_artwork(artwork_in_italy_attrs) }
  let(:artwork_missing_location) { gravity_v1_artwork(missing_artwork_location_attrs) }

  let(:us_shipping_info) do
    {
      shipping_name: 'Mike',
      buyer_phone_number: '777',
      shipping_address_line1: '401 Broadway',
      shipping_country: 'US',
      shipping_city: 'New York',
      shipping_region: 'NY',
      shipping_postal_code: '10013'
    }
  end
  let(:italy_shipping_info) do
    {
      shipping_name: 'Mike',
      buyer_phone_number: '777',
      shipping_address_line1: '3101 A St',
      shipping_country: 'IT',
      shipping_city: 'Como',
      shipping_region: 'Lombardy',
      shipping_postal_code: '99503'
    }
  end
  let(:germany_shipping_info) do
    {
      shipping_name: 'Mike',
      buyer_phone_number: '777',
      shipping_address_line1: 'Möckernstraße 10',
      shipping_country: 'DE',
      shipping_city: 'Berlin',
      shipping_region: 'Berlin',
      shipping_postal_code: '10963'
    }
  end

  let(:fulfillment_type) { Order::SHIP }
  let(:shipping_info) { us_shipping_info }
  let(:order) { Fabricate(:order, fulfillment_type: fulfillment_type, **shipping_info) }

  describe '#calculate' do
    context 'with pickup fulfillment type' do
      let(:fulfillment_type) { Order::PICKUP }

      it 'returns 0' do
        expect(ShippingCalculator.new(artwork, order).calculate).to eq 0
      end
    end

    context 'when artwork is consigned' do
      it 'returns 0' do
        artwork[:import_source] = 'convection'
        expect(ShippingCalculator.new(artwork, order).calculate).to eq 0
      end
    end

    context 'with missing artowrk location' do
      context 'for inquiry order' do
        it 'returns nil' do
          order.impulse_conversation_id = '401'
          expect(ShippingCalculator.new(artwork_missing_location, order).calculate).to be_nil
        end
      end

      context 'for non-inquiry order' do
        it 'raises an error' do
          expect { ShippingCalculator.new(artwork_missing_location, order).calculate }.to raise_error do |error|
            expect(error).to be_a(Errors::ValidationError)
            expect(error.code).to eq :missing_artwork_location
            expect(error.data[:artwork_id]).to eq artwork_missing_location[:_id]
          end
        end
      end
    end

    context 'artwork located in continental U.S.' do
      context 'shipping to continental U.S. address' do
        it 'returns domestic cost' do
          expect(ShippingCalculator.new(continental_us_artwork, order).calculate).to eq 100_00
        end

        context 'with nil domestic shipping fee' do
          it 'raises error for non-inquiry order' do
            continental_us_artwork[:domestic_shipping_fee_cents] = nil
            expect { ShippingCalculator.new(continental_us_artwork, order).calculate }.to raise_error do |error|
              expect(error).to be_a(Errors::ValidationError)
              expect(error.code).to eq :missing_domestic_shipping_fee
            end
          end

          it 'returns nil for inquriy order' do
            continental_us_artwork[:domestic_shipping_fee_cents] = nil
            order.impulse_conversation_id = '401'
            expect(ShippingCalculator.new(continental_us_artwork, order).calculate).to be_nil
          end
        end
      end

      context 'shipping to international address' do
        let(:shipping_info) { italy_shipping_info }

        it 'returns international cost' do
          expect(ShippingCalculator.new(continental_us_artwork, order).calculate).to eq 500_00
        end

        context 'with nil international shipping fee' do
          it 'raises error for non-inquiry order' do
            continental_us_artwork[:international_shipping_fee_cents] = nil
            expect { ShippingCalculator.new(continental_us_artwork, order).calculate }.to raise_error do |error|
              expect(error).to be_a(Errors::ValidationError)
              expect(error.code).to eq :unsupported_shipping_location
            end
          end

          it 'returns nil for inquriy order' do
            continental_us_artwork[:international_shipping_fee_cents] = nil
            order.impulse_conversation_id = '401'
            expect(ShippingCalculator.new(continental_us_artwork, order).calculate).to be_nil
          end
        end
      end
    end

    context 'artwork located in Italy' do
      context 'shipping to domestic address' do
        let(:shipping_info) { italy_shipping_info }

        it 'returns domestic cost' do
          expect(ShippingCalculator.new(artwork_in_italy, order).calculate).to eq 100_00
        end

        context 'with nil domestic shipping fee' do
          it 'raises error for non-inquiry order' do
            artwork_in_italy[:domestic_shipping_fee_cents] = nil
            expect { ShippingCalculator.new(artwork_in_italy, order).calculate }.to raise_error do |error|
              expect(error).to be_a(Errors::ValidationError)
              expect(error.code).to eq :missing_domestic_shipping_fee
            end
          end

          it 'returns nil for inquiry order' do
            artwork_in_italy[:domestic_shipping_fee_cents] = nil
            order.impulse_conversation_id = '401'
            expect(ShippingCalculator.new(artwork_in_italy, order).calculate).to be_nil
          end
        end
      end

      context 'shipping to EU local address' do
        let(:shipping_info) { germany_shipping_info }

        it 'returns domestic cost' do
          expect(ShippingCalculator.new(artwork_in_italy, order).calculate).to eq 100_00
        end

        context 'with nil domestic shipping fee' do
          it 'raises error for non-inquiry order' do
            artwork_in_italy[:domestic_shipping_fee_cents] = nil
            expect { ShippingCalculator.new(artwork_in_italy, order).calculate }.to raise_error do |error|
              expect(error).to be_a(Errors::ValidationError)
              expect(error.code).to eq :missing_domestic_shipping_fee
            end
          end

          it 'returns nil for inquiry order' do
            artwork_in_italy[:domestic_shipping_fee_cents] = nil
            order.impulse_conversation_id = '401'
            expect(ShippingCalculator.new(artwork_in_italy, order).calculate).to be_nil
          end
        end
      end

      context 'shipping to international address' do
        let(:shipping_info) { us_shipping_info }

        it 'returns international cost' do
          expect(ShippingCalculator.new(artwork_in_italy, order).calculate).to eq 500_00
        end

        context 'with nil international shipping fee' do
          it 'raises error for non-inquiry order' do
            artwork_in_italy[:international_shipping_fee_cents] = nil
            expect { ShippingCalculator.new(artwork_in_italy, order).calculate }.to raise_error do |error|
              expect(error).to be_a(Errors::ValidationError)
              expect(error.code).to eq :unsupported_shipping_location
            end
          end

          it 'returns nil for inquiry order' do
            artwork_in_italy[:international_shipping_fee_cents] = nil
            order.impulse_conversation_id = '401'
            expect(ShippingCalculator.new(artwork_in_italy, order).calculate).to be_nil
          end
        end
      end
    end
  end
end

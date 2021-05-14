require 'rails_helper'

describe ARTA::Quote do
  describe '.formatted_post_params' do
    before do
      allow(ARTA::Client).to receive(:post)
    end

    context 'when preparing artwork metadata' do
      let(:expected_formatted_params) do
        described_class.formatted_post_params(artwork_hash, list_price_cents)[:request]
      end

      context 'when artwork data present' do
        let(:list_price_cents) { 30000 }

        context 'when artwork is framed' do
          let(:artwork_hash) do
            {
              category: 'Photography',
              framed: true,
              width_cm: 10.7,
              height_cm: 11.0
            }
          end

          it 'returns properly formatted object parameter' do
            expect(expected_formatted_params).to include({
                                                           objects: [
                                                             {
                                                               height: 11.0,
                                                               subtype: 'photograph_framed',
                                                               unit_of_measurement: 'cm',
                                                               width: 10.7,
                                                               value: 300
                                                             }
                                                           ]
                                                         })
          end
        end

        context 'when artwork is not framed' do
          let(:artwork_hash) do
            {
              category: 'Photography',
              framed: false,
              width_cm: 10.7,
              height_cm: 11.0
            }
          end

          it 'returns properly formatted object parameter' do
            expect(expected_formatted_params).to include({
                                                           objects: [
                                                             {
                                                               height: 11.0,
                                                               subtype: 'photograph_unframed',
                                                               unit_of_measurement: 'cm',
                                                               width: 10.7,
                                                               value: 300
                                                             }
                                                           ]
                                                         })
          end
        end
      end

      context 'when some artwork data is nil' do
        let(:list_price_cents) { 30000 }
        let(:artwork_hash) do
          {
            category: 'Photography',
            framed: true,
            width_cm: nil,
            height_cm: 11.0
          }
        end

        it 'returns properly formatted parameters' do
          expect(expected_formatted_params).to include({
                                                         objects: [
                                                           {
                                                             height: 11.0,
                                                             subtype: 'photograph_framed',
                                                             unit_of_measurement: 'cm',
                                                             value: 300
                                                           }
                                                         ]
                                                       })
        end
      end
    end
  end
end

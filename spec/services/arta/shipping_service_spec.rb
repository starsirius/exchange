require 'rails_helper'

describe ARTA::ShippingService do
  describe '.generate_shipping_quotes' do
    let(:response) do
      JSON.parse(File.read('spec/support/fixtures/arta/quote_request_success_response.json'), { symbolize_names: true })
    end

    before do
      allow(Gravity).to receive(:get_artwork).and_return({})
      allow(ARTA::Quote).to receive(:create).and_return(response)
    end

    context 'success' do
      let(:line_item) { Fabricate(:line_item) }

      it 'persists the correct records' do
        expect { described_class.generate_shipping_quotes(line_item: line_item) }.to change { ShippingQuote.count }.by(5)
        expect { described_class.generate_shipping_quotes(line_item: line_item) }.to change { ShippingQuoteRequest.count }.by(1)
      end
    end
  end
end

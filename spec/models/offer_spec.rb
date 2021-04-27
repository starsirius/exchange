require 'rails_helper'

RSpec.describe Offer, type: :model do
  it_behaves_like 'a papertrail versioned model', :offer

  describe 'last_offer?' do
    it "returns true if the offer is the order's last offer" do
      order = Fabricate(:order)
      offer = Fabricate(:offer, order: order)
      order.update!(last_offer: offer)

      expect(offer.last_offer?).to eq(true)
    end

    it "return false if the offer is not the order's last offer" do
      order = Fabricate(:order)
      first_offer = Fabricate(:offer, order: order)
      second_offer = Fabricate(:offer, order: order)

      order.update!(last_offer: second_offer)

      expect(first_offer.last_offer?).to eq(false)
    end
  end

  describe 'buyer_total_cents' do
    let(:shipping_total_cents) { 20 }
    let(:amount_cents) { 100 }
    let(:tax_total_cents) { 5 }
    let(:order) { Fabricate(:order) }
    let(:offer) { Fabricate(:offer, order: order, amount_cents: amount_cents, shipping_total_cents: shipping_total_cents, tax_total_cents: tax_total_cents) }

    context 'offer with all required amounts' do
      it 'sums up amount, tax and shipping' do
        expect(offer.buyer_total_cents).to be 125
      end
    end

    context 'offer without tax' do
      let(:tax_total_cents) { nil }

      it 'returns nil as buyer total' do
        expect(offer.buyer_total_cents).to be nil
      end
    end

    context 'offer without shipping' do
      let(:shipping_total_cents) { nil }

      it 'returns nil as buyer total' do
        expect(offer.buyer_total_cents).to be nil
      end
    end
  end

  describe '#has_definite_total?' do
    let(:shipping_total_cents) { 20 }
    let(:amount_cents) { 100 }
    let(:tax_total_cents) { 5 }
    let(:order) { Fabricate(:order) }
    let(:offer) { Fabricate(:offer, order: order, amount_cents: amount_cents, shipping_total_cents: shipping_total_cents, tax_total_cents: tax_total_cents) }
    context 'amount_cents, shipping_total_cents, and  tax_total_cents present' do
      it 'returns true' do
        expect(offer.has_definite_total?).to be true
      end
    end
    context 'offer without tax' do
      let(:tax_total_cents) { nil }

      it 'returns false' do
        expect(offer.has_definite_total?).to be false
      end
    end

    context 'offer without shipping' do
      let(:shipping_total_cents) { nil }

      it 'returns false' do
        expect(offer.has_definite_total?).to be false
      end
    end

    context 'offer without amount' do
      let(:amount_cents) { nil }

      it 'returns false' do
        expect(offer.has_definite_total?).to be false
      end
    end
  end

  describe '#scopes' do
    describe 'submitted' do
      let!(:offer1) { Fabricate(:offer, submitted_at: Time.zone.now) }
      let!(:offer2) { Fabricate(:offer, submitted_at: nil) }
      let!(:offer3) { Fabricate(:offer, submitted_at: nil) }
      it 'returns submitted offers' do
        expect(Offer.submitted).to match_array [offer1]
      end
    end
  end

  describe '#from_participant' do
    let(:order) { Fabricate(:order, buyer_id: 'buyer1', buyer_type: 'user', seller_id: 'seller1', seller_type: 'gallery') }
    let(:seller_offer) { Fabricate(:offer, order: order, from_id: 'seller1', from_type: 'gallery') }
    let(:buyer_offer) { Fabricate(:offer, order: order, from_id: 'buyer1', from_type: 'user') }
    let(:ufo_offer) { Fabricate(:offer, order: order, from_id: 'marse', from_type: 'ufo') }
    it 'returns buyer for buyer_offer' do
      expect(buyer_offer.from_participant).to eq Order::BUYER
    end
    it 'returns seller for seller_offer' do
      expect(seller_offer.from_participant).to eq Order::SELLER
    end
    it 'raises error for offer that is not from a buyer or seller' do
      expect { ufo_offer.from_participant }.to raise_error do |error|
        expect(error.type).to eq :validation
        expect(error.code).to eq :unknown_participant_type
      end
    end
  end

  describe '#to_participant' do
    let(:order) { Fabricate(:order, buyer_id: 'buyer1', buyer_type: 'user', seller_id: 'seller1', seller_type: 'gallery') }
    let(:seller_offer) { Fabricate(:offer, order: order, from_id: 'seller1', from_type: 'gallery') }
    let(:buyer_offer) { Fabricate(:offer, order: order, from_id: 'buyer1', from_type: 'user') }
    let(:ufo_offer) { Fabricate(:offer, order: order, from_id: 'marse', from_type: 'ufo') }
    it 'returns seller for buyer_offer' do
      expect(buyer_offer.to_participant).to eq Order::SELLER
    end
    it 'returns buyer for seller_offer' do
      expect(seller_offer.to_participant).to eq Order::BUYER
    end
    it 'raises error for offer that is not from a buyer or seller' do
      expect { ufo_offer.from_participant }.to raise_error do |error|
        expect(error.type).to eq :validation
        expect(error.code).to eq :unknown_participant_type
      end
    end
  end
end

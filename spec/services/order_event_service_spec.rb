require 'rails_helper'
require 'support/gravity_helper'

describe OrderEventService, type: :services do
    let(:user_id) { 'user-id' }
    let(:partner_id) { 'partner-id' }
    let(:amount_cents) { 200 }
    let(:note) { nil }
    let(:order_mode) { Order::OFFER }
    let(:state) { Order::PENDING }
    let(:state_reason) { nil }
    # let(:first_offer_at) { 3.days.ago }
    let(:order) { Fabricate(:order, seller_id: user_id, seller_type: Order::USER, state: state, state_reason: state_reason, mode: order_mode) }
    # let!(:line_item) { Fabricate(:line_item, order: order, list_price_cents: 500) }
    let!(:offer) { Fabricate(:offer, order: order, submitted_at: 3.day.ago,  amount_cents: 1000_00, tax_total_cents: 20_00, shipping_total_cents: 30_00, creator_id: user_id, from_id: user_id) }    
    # let(:counter_offer) { Fabricate(:offer, order: order, responds_to: offer, amount_cents: 10000, submitted_at: 1.day.ago) }



    before do
        # OfferService.create_pending_offer(order, amount_cents: amount_cents, note: note, from_id: user_id, from_type: Order::USER, creator_id: user_id)
        # OfferService.submit_order_with_offer(offer, user_id: user_id)
        
        order.send(:submit!)
        order.update!(last_offer: offer)
        seller_offer = OfferService.create_pending_counter_offer(offer, amount_cents: 20000, note: note, from_id: partner_id, creator_id: user_id, from_type: Order::PARTNER)
            OfferService.accept_offer(seller_offer, 'user_1')        
        rescue => e
            byebug
    end
    describe '#events_for' do
        it "generates events" do
            events = OrderEventService.events_for(order_id: order.id)
            byebug
            expect(events.length).to be 3
        end
    end
end

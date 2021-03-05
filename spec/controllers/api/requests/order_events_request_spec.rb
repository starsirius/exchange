require 'rails_helper'

describe Api::GraphqlController, type: :request do
  include_context 'GraphQL Client'
  describe 'query for order events' do

    let(:seller_id) { jwt_partner_ids.first }
    let(:second_seller_id) { 'partner-2' }
    let(:user_id) { jwt_user_id }
    let(:second_user) { 'user2' }
    let(:order_mode) { Order::OFFER }
    let(:order_created_at) { 2.days.ago }

    # let(:state) { Order::PENDING }
    let(:fulfillment_type) { Order::SHIP }
    let(:impulse_conversation_id) { nil }
    let!(:user1_order1) do
      Fabricate(
        :order,
        mode: order_mode,
        fulfillment_type: fulfillment_type,
        seller_id: seller_id,
        seller_type: 'gallery',
        buyer_id: user_id,
        buyer_type: 'user',
        created_at: order_created_at,
        updated_at: 1.day.ago,
        shipping_total_cents: 100_00,
        commission_fee_cents: 50_00,
        commission_rate: 0.10,
        seller_total_cents: 50_00,
        buyer_total_cents: 100_00,
        items_total_cents: 0,
        state: Order::PENDING,
        state_reason: nil,
        impulse_conversation_id: impulse_conversation_id
      )
    end
    let!(:user2_order1) { Fabricate(:order, seller_id: second_seller_id, seller_type: 'gallery', buyer_id: second_user, buyer_type: 'user', items_total_cents: 0) }

    let(:query) do
      <<-GRAPHQL
        query($id: ID) {
          order(id: $id) {
            orderEvents {
                __typename
                createdAt
                ... on OfferEvent {
                  payload {
                      amountCents
                      fromParticipant
                  }
                  
                }
                ... on OrderEvent {
                  payload {
                    state
                    reason
                  }
                }
              }
          }
        }
      GRAPHQL
    end

    context 'buy order' do
      it 'returns not found error when query for orders by user not in jwt' do
        expect do
          client.execute(query, id: user2_order1.id)
        end.to raise_error do |error|
          expect(error).to be_a(Graphlient::Errors::ServerError)
          expect(error.message).to eq 'the server responded with status 404'
          expect(error.status_code).to eq 404
          expect(error.response['errors'].first['extensions']['code']).to eq 'not_found'
          expect(error.response['errors'].first['extensions']['type']).to eq 'validation'
        end
      end



      context 'with offers' do
        let!(:user1_order1) do
          Fabricate(
            :order,
            mode: Order::OFFER,
            fulfillment_type: fulfillment_type,
            seller_id: seller_id,
            seller_type: 'gallery',
            buyer_id: user_id,
            buyer_type: 'user',
            created_at: 10.minutes.ago,
            updated_at: 1.day.ago,
            shipping_total_cents: 100_00,
            commission_fee_cents: 50_00,
            commission_rate: 0.10,
            seller_total_cents: 50_00,
            buyer_total_cents: 100_00,
            items_total_cents: 0,
            state: Order::PENDING,
            state_reason: nil,
            impulse_conversation_id: impulse_conversation_id
          )
        end
        # let(:state) { Order::SUBMITTED }
        # let(:order_mode) { Order::OFFER }
        # let!(:buyer_offer) { Fabricate(:offer, order: user1_order1, amount_cents: 200, from_id: user_id, from_type: Order::USER, submitted_at: Date.new(2018, 1, 1)) }
        # let!(:seller_offer) { Fabricate(:offer, order: user1_order1, amount_cents: 300, from_id: seller_id, from_type: 'gallery', responds_to_id: buyer_offer.id, submitted_at: Date.new(2018, 1, 2)) }
        # let!(:pending_buyer_offer) { Fabricate(:offer, order: user1_order1, amount_cents: 200, from_id: user_id, from_type: Order::USER) }

        before do
          # allow(user1_order1).to_receive(:valid_artwork_version?).and_return(true)
          # allow(user1_order1).to_receive(:deduct_inventory).and_return(true)
          user1_order1.submit!
          user1_order1.offers.create!(amount_cents: 200, from_id: user_id, from_type: Order::USER, submitted_at: 9.minutes.ago)
          user1_order1.offers.create!(amount_cents: 300, from_id: seller_id, from_type: Order::PARTNER, submitted_at: 8.minutes.ago)
          last_offer = user1_order1.offers.create!(amount_cents: 250, from_id: user_id, from_type: Order::USER, submitted_at: 7.minutes.ago)
          user1_order1.update! last_offer: last_offer
        end

        describe 'the query result' do
          # let(:result) { client.execute(query, id: user1_order1.id) }

          it 'excludes pending offers' do
            puts auth_headers
            result = client.execute(query, id: user1_order1.id)
          
            expect(result.data.order.orderEvents).to eq "hello world"
            # expect(result.data.order.offers.edges.count).to eq 2
            # expect(result.data.order.offers.edges.map(&:node).map(&:id)).to match_array [buyer_offer.id, seller_offer.id]
            # expect(result.data.order.offers.edges.map(&:node).map(&:amount_cents)).to match_array [200, 300]
            # expect(result.data.order.offers.edges.map(&:node).map(&:from).map(&:id)).to match_array [user_id, seller_id]
            # expect(result.data.order.offers.edges.map(&:node).map(&:from).map(&:__typename)).to match_array %w[User Partner]
            # expect(result.data.order.offers.edges.first.node.submitted_at).to eq '2018-01-02T00:00:00Z'
          end


        end

     end
    end
  end
end

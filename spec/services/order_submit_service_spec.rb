require 'rails_helper'
require 'support/gravity_helper'

describe OrderSubmitService, type: :services do
  let(:order) { Fabricate(:order, credit_card_id: 'cc-1', fulfillment_type: Order::PICKUP) }
  let(:credit_card) { { external_id: 'card-1', customer_account: { external_id: 'cust-1' } } }
  let(:merchant_account_id) { 'ma-1' }
  let(:charge_success) { { id: 'ch-1' } }
  let(:charge_failure) { { failure_message: 'some_error' } }
  let(:partner_merchant_accounts) { [{ external_id: 'ma-1' }, { external_id: 'some_account' }] }
  let(:authorize_charge_params) do
    {
      source_id: credit_card[:external_id],
      destination_id: merchant_account_id,
      customer_id: credit_card[:customer_account][:external_id],
      amount: order.buyer_total_cents,
      currency_code: order.currency_code
    }
  end

  describe '#submit!' do
    context 'with a partner with a merchant account' do
      context 'with a successful transaction' do
        before(:each) do
          allow(OrderSubmitService).to receive(:get_merchant_account).with(order).and_return(partner_merchant_accounts.first)
          allow(OrderSubmitService).to receive(:get_credit_card).with(order).and_return(credit_card)
          allow(PaymentService).to receive(:authorize_charge).with(authorize_charge_params).and_return(charge_success)
          allow(TransactionService).to receive(:create_success!).with(order, charge_success)
          OrderSubmitService.submit!(order)
        end

        it 'authorizes a charge for the full amount of the order' do
          expect(PaymentService).to have_received(:authorize_charge).with(authorize_charge_params)
        end

        it 'creates a record of the transaction' do
          expect(TransactionService).to have_received(:create_success!).with(order, charge_success)
        end

        it 'updates the order expiration time' do
          expect(order.state_expires_at).to eq(order.state_updated_at + 2.days)
        end

        it 'updates the order state to SUBMITTED' do
          expect(order.state).to eq Order::SUBMITTED
          expect(order.state_updated_at).not_to be_nil
        end

        it 'updates external_charge_id with the id of the charge' do
          expect(order.external_charge_id).to eq(charge_success[:id])
        end
      end

      context 'with an unsuccessful transaction' do
        it 'creates a record of the transaction' do
          allow(OrderSubmitService).to receive(:get_merchant_account).with(order).and_return(partner_merchant_accounts.first)
          allow(OrderSubmitService).to receive(:get_credit_card).with(order).and_return(credit_card)
          allow(PaymentService).to receive(:authorize_charge).with(authorize_charge_params).and_raise(Errors::PaymentError.new('some_error', charge_failure))
          allow(TransactionService).to receive(:create_failure!).with(order, charge_failure)
          expect { OrderSubmitService.submit!(order) }.to raise_error(Errors::PaymentError)
          expect(TransactionService).to have_received(:create_failure!).with(order, charge_failure)
        end
      end
    end

    context 'with a partner without a merchant account' do
      it 'raises an an error and does not call PaymentService' do
        allow(OrderSubmitService).to receive(:get_merchant_account).with(order).and_return(nil)
        expect { OrderSubmitService.submit!(order) }.to raise_error(Errors::OrderError)
        expect(PaymentService).not_to receive(:authorize_charge)
      end
    end
  end

  describe '#get_merchant_account' do
    it 'calls the /merchant_accounts Gravity endpoint' do
      allow(Adapters::GravityV1).to receive(:request).with("/merchant_accounts?partner_id=#{order.partner_id}").and_return(partner_merchant_accounts)
      OrderSubmitService.get_merchant_account(order)
      expect(Adapters::GravityV1).to have_received(:request).with("/merchant_accounts?partner_id=#{order.partner_id}")
    end

    it "returns the first merchant account of the partner's merchant accounts" do
      allow(Adapters::GravityV1).to receive(:request).with("/merchant_accounts?partner_id=#{order.partner_id}").and_return(partner_merchant_accounts)
      result = OrderSubmitService.get_merchant_account(order)
      expect(result).to be(partner_merchant_accounts.first)
    end

    it 'returns nil if the partner does not have a merchant account' do
      allow(Adapters::GravityV1).to receive(:request).with("/merchant_accounts?partner_id=#{order.partner_id}").and_return([])
      result = OrderSubmitService.get_merchant_account(order)
      expect(result).to be(nil)
    end
  end

  describe '#get_credit_card' do
    it 'calls the /credit_card Gravity endpoint' do
      allow(Adapters::GravityV1).to receive(:request).with("/credit_card/#{order.credit_card_id}")
      OrderSubmitService.get_credit_card(order)
      expect(Adapters::GravityV1).to have_received(:request).with("/credit_card/#{order.credit_card_id}")
    end
  end
end

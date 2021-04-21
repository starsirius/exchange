require 'rails_helper'

describe TransactionFeeCalculator do
  let(:currency) { 'USD' }
  let(:total_charge_amount) { 15000 }

  context 'with transaction fee flag set as true' do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('NEW_TRANSACTION_FEE_ENABLED').and_return(true)
    end
    it 'calculates transaction fee' do
      transaction_fee = TransactionFeeCalculator.calculate(total_charge_amount, currency)
      expect(transaction_fee).to eq 0
    end
  end
  context 'with transaction fee flag set as false' do
    it 'calculates transaction fee' do
      transaction_fee = TransactionFeeCalculator.calculate(total_charge_amount, currency)
      expect(transaction_fee).to eq 615
    end
  end
end

class ShippingQuoteRequest < ApplicationRecord
  belongs_to :line_item
  has_many :shipping_quotes, dependent: :destroy
end

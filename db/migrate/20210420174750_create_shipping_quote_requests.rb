class CreateShippingQuoteRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :shipping_quote_requests, id: :uuid do |t|
      t.references :line_item, foreign_key: true, type: :uuid
      t.string :external_id, null: false
      t.jsonb :response_payload
      t.string :internal_reference
      t.string :public_reference
      t.string :quoted_at
      t.string :expires_at

      t.timestamps
    end
  end
end

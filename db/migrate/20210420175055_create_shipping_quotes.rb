class CreateShippingQuotes < ActiveRecord::Migration[6.1]
  def change
    create_table :shipping_quotes, id: :uuid do |t|
      t.references :shipping_quote_request, foreign_key: true, type: :uuid, null: false
      t.string :tier, null: false
      t.string :name
      t.integer :external_id, null: false
      t.bigint :price_cents, null: false
      t.string :price_currency, null: false

      t.timestamps
    end
  end
end

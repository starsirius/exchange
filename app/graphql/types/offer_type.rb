class Types::OfferType < Types::BaseObject
  description 'An Offer'
  graphql_name 'Offer'

  field :id, ID, null: false
  field :from, Types::OrderPartyUnionType, null: false
  field :state, Types::OfferStateEnum, null: false
  field :amount_cents, Integer, null: false
  field :creator_id, String, null: false
  field :resolved_by_id, String, null: true
  field :resolved_at, Types::DateTimeType, null: true
  field :created_at, Types::DateTimeType, null: false
  field :order, Types::OrderType, null: false
  field :responds_to, Types::OfferType, null: true

  def from
    OpenStruct.new(
      id: object.from_id,
      type: object.from_type
    )
  end
end

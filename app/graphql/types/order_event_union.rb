module Types::EventInterface
  include Types::BaseInterface
  field :created_at, Types::DateTimeType, null: false
end

class Types::OfferSubmittedEvent < Types::BaseObject
  implements Types::EventInterface
  field :payload, Types::OfferType, null: false
end

class Types::OrderStateChangePayload < Types::BaseObject
  field :state: Types::OrderStateEnum, null: false
  field :state_reason, String, null: true
end

class Types::OrderStateChangedEvent < Types::BaseObject
  implements Types::EventInterface
  field :payload, Types::OrderStateChangePayload, null: false
end

class Types::OrderEventUnion < Types::BaseUnion
  description 'Represents either a state change or new offer'
  possible_types Types::OfferSubmittedEvent, Types::OrderStateChangedEvent
  def self.resolve_type(object, _context)
    case object
    when OrderEventService::OfferSubmitted
      Types::OfferSubmittedEvent
    else
      Types::OrderStateChangedEvent
    end
  end
end

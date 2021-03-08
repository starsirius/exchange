module Types::EventInterface
  include Types::BaseInterface
  field :created_at, Types::DateTimeType, null: false
end

class Types::OfferSubmittedEvent < Types::BaseObject
  implements Types::EventInterface
  # field :payload, Types::OfferType, null: false
  field :offer, Types::OfferType, null: false
end

class Types::OrderStateChangedEvent < Types::BaseObject
  # class Payload < Types::BaseObject
  #   field :state, Types::OrderStateEnum, null: false
  #   field :state_reason, String, null: true
  # end

  implements Types::EventInterface
  # field :payload, Payload, null: false
  field :type, Types::OrderStateEnum, null: false
  field :state_reason, String, null: true
end

class Types::OrderEventUnion < Types::BaseUnion
  description 'Represents either a state change or new offer'
  possible_types Types::OfferSubmittedEvent, Types::OrderStateChangedEvent
  def self.resolve_type(object, _context)
    case object
    when OrderHistoryService::OfferSubmitted
      Types::OfferSubmittedEvent
    else
      Types::OrderStateChangedEvent
    end
  end
end

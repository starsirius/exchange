module Types::EventInterface
  include Types::BaseInterface
  field :created_at, Types::DateTimeType, null: false
end

class Types::OfferEvent < Types::BaseObject
  implements Types::EventInterface
  field :offer, Types::OfferType, null: false
end

class Types::OrderEvent < Types::BaseObject
  implements Types::EventInterface
  field :type, Types::OrderStateEnum, null: false
  field :state_reason, String, null: true
end

class Types::OrderEventUnion < Types::BaseUnion
  description 'Represents either a state change or new offer'
  possible_types Types::OfferEvent, Types::OrderEvent
  def self.resolve_type(object, _context)
    case object
    when OrderEventService::OfferEvent
      Types::OfferEvent
    else
      Types::OrderEvent
    end
  end
end

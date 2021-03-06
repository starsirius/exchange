class OrderHistoryService
  OfferSubmitted = Struct.new(:created_at, :offer)
  OrderStateChanged = Struct.new(:created_at, :type, :state_reason, keyword_init: true)
  ## Another possibility
  # OrderHistoryEvent = Struct.new(:event_name, :created_at, :payload)
  # usage: OrderHistoryEvent.new("OfferSubmitted", offer.submitted_at, offer)
  #        OrderHistoryEvent.new("ORDER_#{state_history.state}", state_history.created_at, state_reason: state_history.reason)

  def self.events_for(order_id:)
    order = Order.find(order_id)
    offer_events = offer_events(order)
    state_events = state_events(order)
    sorted_events(offer_events.concat(state_events))
  end

  def self.offer_events(order)
    order.offers.submitted.map { |offer| OfferSubmitted.new(offer.submitted_at, offer) }
  end

  def self.state_events(order)
    order.state_histories.map do |state_history|
      OrderStateChanged.new(created_at: state_history.created_at, type: state_history.state, state_reason: state_history.reason)
    end
  end

  def self.sorted_events(events)
    events.sort_by(&:created_at)
  end
end

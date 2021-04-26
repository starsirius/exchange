class ShippingCalculator
  attr_reader :artwork, :order

  def initialize(artwork, order)
    @artwork = artwork
    @order = order
  end

  def calculate
    return 0 if pickup? || consignment?

    raise Errors::ValidationError.new(:missing_artwork_location, artwork_id: artwork[:_id]) if artwork[:location].blank? && !order.inquiry_order?

    return if artwork[:location].blank? || !order.shipping_info?

    cents = nil

    if domestic? || eu_local_shipping?
      cents = artwork[:domestic_shipping_fee_cents]
      raise Errors::ValidationError, :missing_domestic_shipping_fee if cents.blank? && !order.inquiry_order?
    else
      cents = artwork[:international_shipping_fee_cents]
      raise Errors::ValidationError, :unsupported_shipping_location if cents.blank? && !order.inquiry_order?
    end

    cents
  end

  private

  def consignment?
    artwork[:import_source] == 'convection'
  end

  def pickup?
    order.fulfillment_type == Order::PICKUP
  end

  def shipping_address
    order.shipping_address
  end

  def artwork_country
    artwork.dig(:location, :country)
  end

  def shipping_country
    shipping_address&.country
  end

  def domestic?
    artwork_country.casecmp(shipping_country).zero? &&
      (shipping_country != Carmen::Country.coded('US').code || shipping_address.continental_us?)
  end

  def eu_local_shipping?
    artwork[:eu_shipping_origin] && shipping_address.eu_shipping?
  end
end

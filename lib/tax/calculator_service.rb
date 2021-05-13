class Tax::CalculatorService
  REMITTING_STATES = [].freeze
  def initialize(
    total_amount_cents:,
    quantity:,
    unit_price_cents:,
    fulfillment_type:,
    shipping_address:,
    shipping_total_cents:,
    artwork_location:,
    nexus_addresses:,
    tax_client: Taxjar::Client.new(
      api_key: Rails.application.config_for(:taxjar)['taxjar_api_key'],
      api_url: Rails.application.config_for(:taxjar)['taxjar_api_url'].presence
    )
  )
    @seller_nexus_addresses = process_nexus_addresses!(nexus_addresses)
    @fulfillment_type = fulfillment_type
    @tax_client = tax_client
    @artwork_location = artwork_location
    @shipping_address = shipping_address
    @shipping_total_cents = shipping_total_cents
    @transaction = nil
    @refund = nil
    @quantity = quantity
    @unit_price_cents = unit_price_cents
    @total_amount_cents = total_amount_cents
  end

  def sales_tax
    address_taxable?(@artwork_location) ? fetch_sales_tax : 0
  rescue Taxjar::Error => e
    raise Errors::ProcessingError.new(:tax_calculator_failure, message: e.message)
  end

  def artsy_should_remit_taxes?
    return false unless address_taxable?(destination_address)

    REMITTING_STATES.include? destination_address.region.downcase
  end

  private

  def fetch_sales_tax
    tax_params = construct_tax_params(
      line_items: [{
        unit_price: UnitConverter.convert_cents_to_dollars(@unit_price_cents),
        quantity: @quantity
      }]
    )

    UnitConverter.convert_dollars_to_cents(
      @tax_client.tax_for_order(tax_params).amount_to_collect
    )
  end

  def construct_tax_params(args = {})
    {
      amount: UnitConverter.convert_cents_to_dollars(@total_amount_cents),
      to_country: destination_address.country,
      to_zip: destination_address.postal_code,
      to_state: destination_address.region,
      to_city: destination_address.city,
      to_street: destination_address.street_line1,
      nexus_addresses: @seller_nexus_addresses.map do |ad|
        {
          country: ad.country,
          zip: ad.postal_code,
          state: ad.region,
          city: ad.city,
          street: ad.street_line1
        }
      end,
      shipping: UnitConverter.convert_cents_to_dollars(@shipping_total_cents)
    }.merge(args)
  end

  def destination_address
    @destination_address ||=
      begin
        address = @fulfillment_type == Order::SHIP ? @shipping_address : @artwork_location
        validate_destination_address!(address)
        address
      rescue Errors::ValidationError => e
        raise Errors::ValidationError, :invalid_artwork_address if @fulfillment_type == Order::PICKUP

        raise e
      end
  end

  def address_taxable?(address)
    # For the time being, we're only considering addresses in the United States to be taxable.
    address.united_states?
  end

  def validate_destination_address!(destination_address)
    raise Errors::ValidationError, :missing_region if destination_address.region.nil?
    raise Errors::ValidationError, :missing_postal_code if destination_address.postal_code.nil?
  end

  def process_nexus_addresses!(seller_nexus_addresses)
    nexus_addresses = seller_nexus_addresses.select { |ad| address_taxable?(ad) }
    raise Errors::ValidationError, :no_taxable_addresses if nexus_addresses.blank?

    nexus_addresses.each { |ad| validate_nexus_address!(ad) }
    nexus_addresses
  end

  def validate_nexus_address!(nexus_address)
    raise Errors::ValidationError, :invalid_seller_address if nexus_address.region.nil?
  end
end

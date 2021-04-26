class Address
  attr_reader :country, :region, :city, :street_line1, :street_line2, :postal_code

  UNITED_STATES = Carmen::Country.coded('US')
  COUNTRY_CODES_EU_SHIPPING_SET = %w[
    AD AM AT AZ BY BE BA BG HR CY
    CZ DK EE FI FR GE DE HU IT KZ
    LV LI LT LU MD MC ME NL MK NO
    PL PT RO RU SM RS SK SI ES SE
    CH TR UA VA
  ].map { |country_code| Carmen::Country.coded(country_code).code }.to_set

  def initialize(address)
    @address = parse(address)
    @country = @address[:country]
    @region = @address[:region]
    @city = @address[:city]
    @street_line1 = @address[:street_line1]
    @street_line2 = @address[:street_line2]
    @postal_code = @address[:postal_code]
  end

  def ==(other)
    @country == other.country && \
      @region == other.region && \
      @city == other.city && \
      @street_line1 == other.street_line1 && \
      @street_line2 == other.street_line2 && \
      @postal_code == other.postal_code
  end

  def united_states?
    @country == UNITED_STATES.code
  end

  # The "continental United States" is defined as any US state that isn't Alaska or Hawaii.
  def continental_us?
    united_states? &&
      @region != UNITED_STATES.subregions.coded('HI').code &&
      @region != UNITED_STATES.subregions.coded('AK').code
  end

  def eu_shipping?
    COUNTRY_CODES_EU_SHIPPING_SET.include? @country
  end

  private

  def parse(address)
    country = Carmen::Country.coded(address[:country])
    region = address[:region] || address[:state]
    region = parse_region(country, region)
    {
      country: country&.code,
      region: region,
      city: address[:city],
      street_line1: address[:address_line1] || address[:address],
      street_line2: address[:address_line2] || address[:address_2],
      postal_code: address[:postal_code] || address[:zip]
    }
  end

  def parse_region(country, region)
    region = region&.strip
    return region unless country&.code == UNITED_STATES.code || country&.code == Carmen::Country.coded('CA').code

    parsed_region = country.subregions.named(region) || country.subregions.coded(region)
    parsed_region&.code
  end
end

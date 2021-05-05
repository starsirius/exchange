ActiveAdmin.register Order do
  permit_params :shipping_total_cents, :tax_total_cents, :buyer_total_cents, :transaction_fee_cents, :commission_fee_cents, :seller_total_cents, :items_total_cents
  actions :all, except: %i[create destroy new]
  # TODO: change sort order
  config.sort_order = 'state_updated_at_desc'

  config.action_items.delete_if { |item| item.name == :edit && item.display_on?(:show) }

  scope :all
  scope('Submitted', default: true) { |scope| scope.where(state: Order::SUBMITTED) }
  scope('Active', default: true, &:active)
  scope('Pickup') { |scope| scope.where(state: [Order::APPROVED, Order::FULFILLED, Order::SUBMITTED], fulfillment_type: Order::PICKUP) }
  scope('Fulfillment Overdue') { |scope| scope.approved.where('state_expires_at < ?', Time.zone.now) }
  scope('Completed') { |scope| scope.where(state: Order::FULFILLED) }
  scope('Case Closed') { |scope| scope.by_last_admin_note(AdminNote::TYPES[:case_closed]) }
  scope('Case Still Open') { |scope| scope.by_last_admin_note(AdminNote::TYPES.except(:case_closed).values) }
  scope('Inquiry Offer', &:is_inquiry_order)

  filter :id_eq, label: 'Order Id'
  filter :mode, as: :check_boxes, collection: proc { Order::MODES }, label: 'Type'
  filter :code_eq, label: 'Order Code'
  filter :seller_id_eq, label: 'Seller Id'
  filter :buyer_id_eq, label: 'Buyer Id'
  filter :created_at, as: :date_range, label: 'Submitted Date'
  filter :fulfillment_type, as: :check_boxes, collection: proc { Order::FULFILLMENT_TYPES }
  filter :state, as: :check_boxes, collection: proc { Order::STATES }
  filter :state_reason, as: :check_boxes, collection: proc { Order::REASONS.values.map(&:values).flatten.uniq.map!(&:humanize) }
  filter :has_offer_note, as: :check_boxes, label: 'Has Offer Note'
  filter :assisted

  index do
    column :code do |order|
      link_to order.code, admin_order_path(order.id)
    end
    column 'Fulfillment', :fulfillment_type
    column :mode
    column :state
    column 'At' do |order|
      order.state_updated_at.strftime('%b %e')
    end
    column :state_expires_at
    column 'Items Total' do |order|
      format_money_cents(order.items_total_cents, currency_code: order.currency_code)
    end
  end

  member_action :refund, method: :post do
    OrderService.refund!(resource)
    redirect_to resource_path, notice: 'Refunded!'
  end

  member_action :cancel, method: :post do
    OrderService.reject!(resource, current_user[:id], Order::REASONS[Order::CANCELED][:admin_canceled])
    redirect_to resource_path, notice: 'Canceled by Artsy admin!'
  end

  member_action :buyer_reject, method: :post do
    OrderService.reject!(resource, resource.buyer_id, Order::REASONS[Order::CANCELED][:buyer_rejected])
    redirect_to resource_path, notice: 'Canceled on behalf of buyer!'
  end

  member_action :approve_order, method: :post do
    OrderService.approve!(resource, current_user[:id])
    redirect_to resource_path, notice: 'Order approved!'
  end

  member_action :accept_offer, method: :post do
    return unless resource.mode == Order::OFFER && resource.state == Order::SUBMITTED

    OfferService.accept_offer(resource.last_offer, current_user[:id])
    redirect_to resource_path, notice: 'Offer accepted!'
  end

  member_action :confirm_pickup, method: :post do
    OrderService.confirm_fulfillment!(resource, current_user[:id], fulfilled_by_admin: true) if resource.fulfillment_type == Order::PICKUP
    redirect_to resource_path, notice: 'Fulfillment confirmed!'
  end

  member_action :confirm_fulfillment, method: :post do
    OrderService.confirm_fulfillment!(resource, current_user[:id], fulfilled_by_admin: true) if resource.fulfillment_type == Order::SHIP
    redirect_to resource_path, notice: 'Fulfillment confirmed!'
  end

  member_action :toggle_assisted, method: :post do
    resource.update!(assisted: !resource.assisted)
    redirect_to resource_path, notice: 'toggled assisted flag!'
  end

  action_item :refund, only: :show do
    link_to 'Refund', refund_admin_order_path(order), method: :post, data: { confirm: 'Are you sure you want to refund this order?' } if [Order::APPROVED, Order::FULFILLED].include? order.state
  end

  action_item :buyer_reject, only: :show do
    link_to 'Buyer Reject', buyer_reject_admin_order_path(order), method: :post, data: { confirm: 'Are you sure you want to reject this order on behalf of buyer?' } if order.state == Order::SUBMITTED
  end

  action_item :cancel_order, only: :show do
    link_to 'Cancel Order', cancel_admin_order_path(order), method: :post, data: { confirm: 'Are you sure you want to cancel this order?' } if order.state == Order::SUBMITTED
  end

  action_item :approve_order, only: :show do
    link_to 'Approve Order', approve_order_admin_order_path(order), method: :post, data: { confirm: 'Approve this order?' } if order.state == Order::SUBMITTED && resource.mode == Order::BUY
  end

  action_item :accept_offer, only: :show do
    link_to 'Accept Last Offer', accept_offer_admin_order_path(order), method: :post, data: { confirm: 'Accept last offer on this order?' } if order.state == Order::SUBMITTED && resource.mode == Order::OFFER
  end

  action_item :confirm_pickup, only: :show do
    link_to 'Confirm Pickup', confirm_pickup_admin_order_path(order), method: :post, data: { confirm: 'Confirm order pickup?' } if order.state == Order::APPROVED && order.fulfillment_type == Order::PICKUP
  end

  action_item :confirm_fulfillment, only: :show do
    link_to 'Confirm Fulfillment', confirm_fulfillment_admin_order_path(order), method: :post, data: { confirm: 'Confirm order fulfillment?' } if order.state == Order::APPROVED && order.fulfillment_type == Order::SHIP
  end

  action_item :toggle_assisted_flag, only: :show do
    link_to 'Toggle Assisted', toggle_assisted_admin_order_path(order), method: :post if order.state != Order::PENDING
  end

  action_item :confirm_offline_sale, only: :show do
    link_to 'Confirm Offline Sale', edit_admin_order_path(order[:id]) if [Order::ABANDONED, Order::CANCELED].include?(order.state)
  end

  sidebar :artwork_info, only: :show do
    order.line_items.each do |line_item|
      artwork_info = Gravity.get_artwork(line_item.artwork_id)

      if artwork_info.present?
        if artwork_info[:images].is_a?(Array)
          square_image = artwork_info[:images].find { |im| im[:image_urls].key?(:square) }
          img src: square_image[:image_urls][:square], width: '100%' if square_image
        end

        attributes_table_for order do
          row 'artwork id' do
            artwork_info[:_id]
          end

          row 'artwork title' do
            link_to "#{artwork_info[:title]} by #{artwork_info[:artist][:name]}", artsy_view_artwork_url(line_item.artwork_id) if artwork_info.key?(:title)
          end

          row 'import source' do
            artwork_info[:import_source]
          end

          row 'external id' do
            artwork_info[:external_id]
          end
        end
      else
        h3 'Failed to fetch artwork'
      end
    end
  end

  sidebar :buyer_information, only: :show do
    user_info = Gravity.get_user(order.buyer_id)

    attributes_table_for order do
      if user_info.present?
        row 'Name' do
          user_info[:name]
        end
        row 'Location' do
          if user_info[:location][:display].empty?
            div 'No location for user'
          else
            user_info[:location][:display]
          end
        end
        row 'Email' do
          user_info[:email]
        end
      end

      if order.fulfillment_type == Order::SHIP
        row :shipping_name
        row :shipping_address do
          if order.shipping_info?
            div order.shipping_address_line1
            div order.shipping_address_line2
            div "#{order.shipping_city}, #{order.shipping_region} #{order.shipping_postal_code}"
            div order.shipping_country
          else
            'None'
          end
        end
        row 'Shipping Phone' do
          number_to_phone order.buyer_phone_number
        end
      end
    end

    h5 link_to('View User in Admin', artsy_view_user_admin_url(order.buyer_id), class: :button) if order.buyer_type == 'user'
  end

  sidebar :seller_information, only: :show do
    partner_info = Gravity.fetch_partner(order.seller_id)

    if partner_info.present?
      valid_partner_location = true
      begin
        partner_locations = Gravity.fetch_partner_locations(order.seller_id)
      rescue Errors::ValidationError
        valid_partner_location = false
      end

      if valid_partner_location
        # TODO: - handle multiple partner_locations properly, instead of just taking the first.
        partner_location = partner_locations.first
        partner_info[:partner_location] = partner_location
        attributes_table_for partner_info do
          row :name
          row :partner_location do |partner|
            partner_location = partner[:partner_location]
            div partner_location.street_line1
            div partner_location.street_line2
            div "#{partner_location.city}, #{partner_location.region} #{partner_location.postal_code}"
          end
          row :email
        end
      else
        h3 'Failed to fetch partner location info'
      end
      h5 link_to('View Partner in Admin-Partners', artsy_view_partner_admin_url(order.seller_id), class: :button)
    else
      h3 'Failed to fetch partner info'
    end
  end

  show do
    panel 'Order Summary' do
      attributes_table_for order do
        row :code
        row 'Type', &:mode
        row :state
        row 'Reason', &:state_reason
        row 'Last Updated At', &:updated_at

        last_admin_note = order.last_admin_note
        row 'Last admin action' do |_order|
          last_admin_note.note_type.humanize if last_admin_note.present?
        end
        row :assisted
        row 'Last note' do |_order|
          last_admin_note.description if last_admin_note.present?
        end

        row 'Last Transaction Failed', &:last_transaction_failed?

        if order.state == Order::FULFILLED && order.fulfillment_type == Order::SHIP
          row 'Shipment' do |order|
            fulfillments = order.line_items.map(&:fulfillments).flatten
            table_for fulfillments do
              column '' do |fulfillment|
                attributes_table_for fulfillment do
                  row :courier
                  row :tracking_id
                  row :estimated_delivery
                end
              end
            end
          end
        end
      end
      br

      table_for order.state_histories do
        column 'Date', :created_at
        column :state
        column :reason
      end
    end

    if order.mode == Order::OFFER
      panel "Negotiation (#{order.offers.submitted.count})" do
        events = []

        order.offers.submitted.order(created_at: :desc).each do |offer|
          date = offer.created_at
          amount = format_money_cents(offer.amount_cents, currency_code: offer.order.currency_code)

          if order.state == Order::APPROVED && order.last_offer == offer
            events << {
              description: "#{offer.to_participant.capitalize} approved #{offer.from_participant}'s offer",
              amount: amount,
              date: date
            }
          end

          events << if offer.responds_to
            {
              description: "#{offer.from_participant.capitalize} made a counteroffer",
              amount: amount,
              date: date,
              note: offer.note
            }
          else
            {
              description: 'Buyer made an initial offer',
              amount: amount,
              date: date,
              note: offer.note
            }
          end
        end
        table_for(events) do
          column 'Date', :date
          column 'Action', :description
          column 'Amount', :amount
          column 'Note', :note
        end
      end
    end

    panel 'Transaction' do
      if order.credit_card_id.present?
        no_credit_card_found = false
        begin
          credit_card_info = Gravity.get_credit_card(order.credit_card_id)
          no_credit_card_found = credit_card_info.blank?
        rescue StandardError
          no_credit_card_found = true
        end
        if no_credit_card_found
          h5 "Paid #{format_money_cents(order.buyer_total_cents, currency_code: order.currency_code)} on #{pretty_format(order[:created_at])} (Failed to get credit card info)"
        else
          h5 "Paid #{format_money_cents(order.buyer_total_cents, currency_code: order.currency_code)} with #{credit_card_info[:brand]} ending in #{credit_card_info[:last_digits]} on #{pretty_format(order[:created_at])}"
        end
      end

      attributes_table_for order do
        row 'Artwork List Price' do |_order|
          format_money_cents(order.total_list_price_cents, currency_code: order.currency_code)
        end
        if order.mode == Order::OFFER
          row 'Accepted Offer' do |_order|
            format_money_cents(order.items_total_cents, currency_code: order.currency_code)
          end
        end

        row 'Shipping' do |order|
          format_money_cents(order.shipping_total_cents, currency_code: order.currency_code)
        end
        row 'Sales Tax' do |order|
          format_money_cents(order.tax_total_cents, currency_code: order.currency_code)
        end
        row 'Buyer Paid' do |order|
          format_money_cents(order.buyer_total_cents, currency_code: order.currency_code)
        end
        row 'Processing Fee' do |order|
          format_money_cents(order.transaction_fee_cents, currency_code: order.currency_code, negate: true)
        end
        row 'Artsy Fee' do |order|
          format_money_cents(order.commission_fee_cents, currency_code: order.currency_code, negate: true)
        end
        row 'Seller Payout' do |order|
          format_money_cents(order.seller_total_cents, currency_code: order.currency_code)
        end
      end

      table_for order.transactions do
        column 'Date', :created_at
        column 'Type', :external_type
        column 'Action', :transaction_type
        column 'Status', :status
        column :failure_code
        column :failure_message
        column :decline_code
      end
    end

    panel 'Admin Actions and Notes' do
      h5 link_to('Add note', new_admin_order_admin_note_path(order), class: :button)
      table_for(order.admin_notes.order(created_at: :desc)) do
        column :created_at
        column 'Admin' do |fraud_review|
          Gravity.get_user(fraud_review.admin_id)[:name]
        end
        column 'Note Type' do |admin_note|
          admin_note.note_type.to_s.humanize
        end
        column :description
      end
    end

    panel 'Fraud Review' do
      h5 link_to('Add fraud review', new_admin_order_fraud_review_path(order), class: :button)
      table_for(order.fraud_reviews.order(created_at: :desc)) do
        column :created_at
        column 'Reviewed by' do |fraud_review|
          Gravity.get_user(fraud_review.admin_id)[:name]
        end
        column :flagged_as_fraud
        column :reason
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :offline_sale_date, as: :date_picker, input_html: { value: Time.zone.today }, label: 'Offline sale date'
      f.input :admin_note_description, as: :string, input_html: { value: '' }, label: 'Admin note'
      f.input :total_list_price_cents, as: :number, input_html: { value: order.total_list_price_cents }, label: "Artwork list price (#{order.currency_code} cents)"
      f.input :items_total_cents, as: :number, label: "Accepted offer (#{order.currency_code} cents)" if order.mode == Order::OFFER
      f.input :shipping_total_cents, as: :number, label: "Shipping (#{order.currency_code} cents)"
      f.input :tax_total_cents, as: :number, label: "Sales Tax (#{order.currency_code} cents)"
      f.input :buyer_total_cents, as: :number, label: "Buyer Paid (#{order.currency_code} cents)"
      f.input :transaction_fee_cents, as: :number, label: "Processing Fee (#{order.currency_code} cents)"
      f.input :commission_fee_cents, as: :number, label: "Artsy Fee (#{order.currency_code} cents)"
      f.input :seller_total_cents, as: :number, label: "Seller Payout (#{order.currency_code} cents)"
    end
    f.actions
  end

  controller do
    def update
      offline_sale_date = params[:order].delete(:offline_sale_date)
      admin_note_description = params[:order].delete(:admin_note_description)
      total_list_price_cents = params[:order].delete(:total_list_price_cents)

      OrderService.confirm_fulfillment!(resource, current_user[:id], fulfilled_by_admin: true)

      # update fulfilled state change timestamp to the `offline_sale_date` provided in the form
      fulfillment_state = resource.state_histories.where(state: Order::FULFILLED).order(created_at: :asc).last
      fulfillment_state&.update!(created_at: offline_sale_date)

      resource.update_total_list_price_cents(total_list_price_cents)

      resource.admin_notes.create!(note_type: AdminNote::TYPES[:offline_sale], admin_id: current_user[:id], description: admin_note_description)

      update! do |format|
        format.html { redirect_to admin_order_path(params[:id]) }
      end
    end
  end
end

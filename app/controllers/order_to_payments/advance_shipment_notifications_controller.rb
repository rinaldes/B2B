class OrderToPayments::AdvanceShipmentNotificationsController < ApplicationController
  layout 'main'
  before_filter :find_po, :only=>[:new_asn, :show, :generate_pdf_details_asn, :generate_xls_details_asn]
  before_filter :find_asn, :only=>[:create_asn, :show, :generate_pdf_details_asn, :generate_xls_details_asn]
  before_filter :details_asn, :only=>[:show]
  add_breadcrumb "Advance Shipment Notifications", :order_to_payments_advance_shipment_notifications_path
  # load_and_authorize_resource :class=>"PurchaseOrder"

  def index
    @results = PurchaseOrder.search(params).order("created_at DESC").where("is_completed = true and is_history = false and is_published = true AND asn_state NOT IN (5, 6)").where(:order_type => "#{ASN}")
      .accessible_by(current_ability)#.page(params[:page])
    if (params["format"]=="xls")
      @results_all = PurchaseOrder.search(params).order("created_at DESC").where("is_completed = true and is_history = false and is_published = true").where(:order_type => "#{ASN}")
        .accessible_by(current_ability)
    end
    respond_to do |format|
      format.html
      format.js
      format.xls
    end
  end

  def generate_pdf_details_asn
    @asn_disputed = PurchaseOrder.where(:po_number => "#{@asn.po_number}", :order_type => "#{ASN}").order("created_at ASC")
    @asn_details = @asn_disputed.last.details_purchase_orders.order("seq ASC")
    render :pdf => "ASN-#{@asn.asn_number}",
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'order_to_payments/advance_shipment_notifications/asn.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def generate_xls_details_asn
    send_file @asn.export_to_xls, :disposition => 'inline', :type => 'application/xls', :filename => "ASN-#{@asn.po_number}.xls"
  end

  def show
    add_breadcrumb "Advance Shipment Notifications Detail", order_to_payments_advance_shipment_notification_path(params[:id])
  end

  def generate_pdf_all_asn
      title = "ASN_ALL_#{Time.new.strftime('%d-%m-%Y')}"
      @results = PurchaseOrder.search(params).order("created_at DESC").where("is_completed = true and is_history = false and is_published = true").where(:order_type => "#{ASN}").accessible_by(current_ability)
      render :pdf => title,
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'order_to_payments/advance_shipment_notifications/asn_all.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def new_asn
    @draft_asn = PurchaseOrder.draft_asn_existed? @po.po_number
    unless @draft_asn.nil?
      @asn = @draft_asn
      @details=@asn.details_purchase_orders
    else
      @asn=PurchaseOrder.new
      @asn.details_purchase_orders.build
      @details=@po.details_purchase_orders
    end
  end

  #Desc : membuat ASN baru
  def create_asn
    #desc : save asn menjadi draft
    if params[:save_asn]
      unless @asn.blank?
        @flag = @asn.update_attributes(params[:purchase_order])
        if @flag
          @message = "ASN is saved"
        else
          @message = "An error has ocurred on saving ASN, please try again"
        end
      else
        @asn = PurchaseOrder.fill_for_new_blank_asn(params, current_user)
        if @asn.instance_of? PurchaseOrder
          if @flag = @asn.asn_saved?
            @message = "ASN is saved"
          else
            @message = "An error has ocurred on saving ASN, please again"
          end
        else
          @flag = false
          @message = "Opps, you just can't do that"
        end
      end
    #desc : ketika menekan button publish
    elsif params[:publish_asn]
      unless @asn.blank?
        if @flag = @asn.published?(params[:purchase_order], current_user)
          @message = "ASN is published"
        else
          @message = "An error has ocurred on publishing ASN, please again"
        end
      else
        @asn = PurchaseOrder.fill_for_new_blank_asn(params,current_user)
        if @flag = @asn.published?(params, current_user)
          @message = "ASN is published"
        else
          @message = "An error has ocurred on publishing ASN, please again"
        end
      end
    end
  end

  def edit
    add_breadcrumb "Advance Shipment Notifications Edit", order_to_payments_advance_shipment_notification_path(params[:id])

    @asn = PurchaseOrder.where(:id=>params[:id], :order_type=> "#{ASN}").last
  end

  def destroy
    @asn = PurchaseOrder.find(params[:id])
    po = PurchaseOrder.where(:po_number => @asn.po_number, :order_type => "#{PO}").first
    po.cancelled_po if po.can_cancelled_po?

    OffsetApi.push_data("b2basn", @asn.prep_json)
    @asn.update_attributes(asn_state: 6)

    respond_to do |format|
      format.html { redirect_to order_to_payments_advance_shipment_notifications_path, notice: 'ASN was successfully cancelled.' }
    end
  end

  def update
    respond_to do |format|
      asn = PurchaseOrder.find(params[:id])
      if params[:commit] == 'accept_asn'
        asn.accept_asn
        flash[:notice] = "ASN has been accepted"
        format.js
      elsif asn.update_attributes(params[:purchase_order])
        if current_user.supplier.nil?
          asn.customer_edit_asn
        else
          asn.supplier_edit_asn
        end
        asn.update_attributes(user_id: current_user.id)
        PurchaseOrder.send_notifications(asn)
        flash[:notice] = "ASN details has been changed"
        format.js
      else
        flash[:error] = "An error has ocurred when saving ASN details, please try again later"
        format.html { render :edit }
      end
    end
  end

  private
  def find_asn
    @asn = PurchaseOrder.where(:id=>params[:id], :order_type=> "#{ASN}").last
    @asn.to_read_asn if params[:action] == "show" && @asn.can_to_read_asn? && current_user.roles.map{|a|(a.parent.name rescue nil)}.include?('customer')
  end

  #desc: untuk menampilkan detail ASN
  def details_asn
    if params[:flag] == '0'
      conditions = "commited_qty=0"
    elsif params[:flag] == 'diff'
      conditions = "commited_qty>0 AND commited_qty<order_qty"
    end
    if (@asn.details_purchase_orders.count < @asn.total_line_qty.to_i) || (@asn.details_purchase_orders.count == 0)
      grn = PurchaseOrder.where(:po_number=>@asn.po_number, :is_history=>false, :order_type=>"#{GRN}",:is_completed=>true).last
      unless grn.blank?
        if grn.details_purchase_orders.count == 0
          @details = DetailsPurchaseOrder.get_and_save_po_details_from_api(grn)
          case @details
            when 1
              not_found
            when 2
              no_content
            when -1
              redirect_to :back, :alert => "Details have not a tax line, please check again"
            when true
              @details = @asn.details_purchase_orders.where(conditions).order("seq ASC")#.page(params[:page]).per(PER_PAGE)
            else
              something_wrong
          end
        else
          @details = @asn.details_purchase_orders.where(conditions).order("seq ASC")#.page(params[:page]).per(PER_PAGE)
        end
      else
        @details=@asn.details_purchase_orders.where(conditions).order("seq ASC")#.page(params[:page]).per(PER_PAGE)
      end
    else
      @details=@asn.details_purchase_orders.where(conditions).order("seq ASC")#.page(params[:page]).per(PER_PAGE)
    end
  end

  def find_po
    @po=PurchaseOrder.find(params[:id])
    asn_not_found if @po.nil?
  end

  #desc : menampilkan not found page
  def asn_not_found
    respond_to do |format|
      format.html{render :file => "#{Rails.root.join('public','404.html')}",  :status => 404}
      format.js {render :js => "window.location = '#{order_to_payments_purchase_orders_path}'", :status=>404}
    end
  end

end

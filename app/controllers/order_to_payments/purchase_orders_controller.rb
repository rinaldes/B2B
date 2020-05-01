class OrderToPayments::PurchaseOrdersController < ApplicationController
  before_filter :find_object, :only=>[:show, :show_products_po, :get_details, :generate_pdf_details_po, :generate_xls_details_po]
  before_filter :get_details, :only=>[:show, :generate_pdf_details_po]
  before_filter :index, :only=>[:print]
  layout 'main'
  load_and_authorize_resource @results, @po, except: [:generate_pdf_details_po, :generate_xls_details_po]
  add_breadcrumb "Purchase Orders", :order_to_payments_purchase_orders_path

  def index
    @results_all = PurchaseOrder.search(params).order("created_at DESC").where(:order_type=> "#{PO}", :state=>[0, 1]).accessible_by(current_ability).readonly(false)
    @results = @results_all

    if params[:print].present? && params[:print] == "print"
      print(@results) and return
    else
      respond_to do |format|
        format.html
        format.js
        format.xls
      end
    end
  end

  def generate_xls_details_po
    send_file @po.export_to_xls, :disposition => 'inline', :type => 'application/xls', :filename => "PO-#{@po.po_number}.xls"
  end

  def generate_pdf_details_po
    @po_disputed = PurchaseOrder.where(:po_number => "#{@po.po_number}", :order_type => "#{PO}").order("created_at ASC")
    @po_details = @po_disputed.last.details_purchase_orders.order("seq ASC")
    render :pdf => "PO-#{@po.po_number}",
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'order_to_payments/purchase_orders/po.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def show
    add_breadcrumb "Detail", :order_to_payments_purchase_order_path
  end

  def generate_pdf_all_po
      title = "PO_ALL_#{Time.new.strftime('%d-%m-%Y')}"
      @results = PurchaseOrder.search(params).order("created_at DESC").where(:order_type=> "#{PO}", :is_completed=>true).accessible_by(current_ability).readonly(false)
      render :pdf => title,
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'order_to_payments/purchase_orders/po_all.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  #desc : Synch PO ke API
  def synch_po_now
    @results = PurchaseOrder.synch_po_now
    status = eval_status_res(@results)
    send_email_which_service_api_is_not_connected(status)
    respond_to do |f|
      @back_to_index = "#{order_to_payments_purchase_orders_path}"
      f.js {render :layout => false, :status=>status}
    end
  end

  private

  def find_object
  	@po=PurchaseOrder.where("id = ? and order_type like ?",params[:id], "%#{PO}%").last
    not_found if @po.nil?
  end

  def get_details
    if @po.details_purchase_orders.count == 0
      @details = DetailsPurchaseOrder.get_and_save_po_details_from_api(@po)
      case @details
        when 2
          not_found
        when -1
          redirect_to :back, :alert => "Details have not a tax line, please check again"
        when true
          @details = @po.details_purchase_orders.order("seq ASC")#.page(params[:page]).per(PER_PAGE)
        when 3
          redirect_to :back, :alert => "Service API is unavailable right now."
        else
          something_wrong
      end
    else
      @details=@po.details_purchase_orders.order("seq ASC")#.page(params[:page]).per(PER_PAGE)
    end
  end
end

class OrderToPayments::InvoicesController < ApplicationController
  layout 'main'
  add_breadcrumb "Invoices", :order_to_payments_invoices_path
  before_filter :find_inv, :only=>[:show,:print_inv, :print, :respond_to_inv, :get_push_invoice_completed_to_api, :generate_pdf_details_inv, :generate_xls_details_inv, :get_inv_history]
  before_filter :get_details, :only=>[:show]
  before_filter :get_current_company
  load_and_authorize_resource :class=>"PurchaseOrder", except: :generate_pdf_details_inv

  def generate_xls_details_inv
    send_file @inv.export_to_xls, :disposition => 'inline', :type => 'application/xls', :filename => "GRN-#{@inv.invoice_number}.xls"
  end

  def index
    conditions = []
    conditions << "is_completed = true"
    conditions << "is_history = false"
    conditions << "inv_state <> 5"
    conditions << "inv_state <> 1" if current_user.warehouse.present?

    role = current_user.roles.first
    while role.parent_id != nil do role = Role.find(role.parent_id) end

    # Customer non admin hanya bisa melihat invoice yang sudah diprint
    # if role.name.casecmp("superadmin") != 0 && role.name.casecmp("customer") == 0
    #   conditions << "inv_state > 1"
    # end

    @results_all = PurchaseOrder.search(params).order("created_at DESC").where(conditions.join(" and ")).where(:order_type => "#{INV}").accessible_by(current_ability).readonly(false)
    @results = @results_all.page(params[:page])

    respond_to do |format|
      format.html
      format.js
      format.xls
     end
  end

  def generate_pdf_details_inv
    @inv_disputed = PurchaseOrder.where(:po_number => "#{@inv.po_number}", :order_type => "#{INV}").order("created_at ASC")
    @inv_details = @inv_disputed.last.details_purchase_orders.order("seq ASC")
    render :pdf => "GRN-#{@inv.invoice_number}",
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'order_to_payments/invoices/inv.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def show
    add_breadcrumb "Detail", :order_to_payments_invoices_path

    @path = ''
    if @inv.inv_new? || @inv.inv_incomplete?
      @path = order_to_payments_print_inv_path(@inv.id)
    elsif @inv.inv_printed?
      @path = order_to_payments_respond_to_inv_path(@inv.id)
    end
  end

  def generate_pdf_all_inv
      title = "INV_ALL_#{Time.new.strftime('%d-%m-%Y')}"
      @results_ = PurchaseOrder.search(params).order("created_at DESC").where("is_completed = true and is_history = false").where(:order_type => "#{INV}").accessible_by(current_ability).readonly(false)
      render :pdf => title,
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'order_to_payments/invoices/inv_all.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def get_details
    if @inv.details_purchase_orders.count == 0
      @details = DetailsPurchaseOrder.get_and_save_po_details_from_api(@inv)
      case @details
        when 2
          not_found
        when -1
          redirect_to :back, :alert => "Details have not a tax line, please check again"
        when true
          @details = @inv.details_purchase_orders.order("seq ASC").page(params[:page]).per(PER_PAGE)
        when 3
          redirect_to :back, :alert => "Service API is unavailable right now."
        else
          something_wrong
      end
    else
      @details = @inv.details_purchase_orders.order("seq ASC").page(params[:page]).per(PER_PAGE)
    end
  end

  #desc: print logic invoice
  def print_inv
    if @inv.can_print_inv?
      @inv.inv_print_count +=1
      @inv.user_id = current_user.id
      if @inv.update_attributes(params[:purchase_order])
        PurchaseOrder.send_notifications(@inv)
        respond_to do |format|
          format.js
        end
      else
        respond_to do |format|
          format.js
        end
      end
    else
      forbidden
    end
  end

  def respond_to_inv
    @flag = true
    old_attr = @inv.attributes
    if @inv.inv_printed?
      if params[:commit] == 'receive'
        received_inv = @inv.process_print_inv(params, current_user)
        ret = received_inv.respond_to_inv(params, current_user)
        updated_received_inv = PurchaseOrder.find received_inv.id
        PurchaseOrder.send_notifications(updated_received_inv)
        case ret
        when true
          flash[:notice] = "Invoice was received"
          respond_to do |format|
            format.js{
              render :js=> "window.location= '#{order_to_payments_invoices_path}'"
            }
          end
        when 2
          @flag = 2
          @message = "Service is unavalaible right now, please try again later"
        else
          @flag = false
          @message = "Error on saving Invoice, please try again"
        end
      elsif params[:reject]
        rejected_inv = @inv.process_print_inv(params, user)
        if rejectd_inv
          rejected_inv.reject_inv
          updated_rejected_inv = PurchaseOrder.find rejected_inv.id
          PurchaseOrder.send_notifications(updated_rejected_inv)
          flash[:notice] = "Invoice rejected"
          respond_to do |format|
            format.js{
              render :js=> "window.location= '#{order_to_payments_invoices_path}'"
            }
          end
        else
          @flag = false
          @message = "Error on saving Invoice, please try again"
        end
      end
    elsif (@inv.inv_new? || @inv.inv_incomplete?) && can?(:print_inv, :invoice)
      if @inv.update_attributes(params[:purchase_order].merge(tax_gap: params[:selisih_tax].gsub('Rp', '').gsub('.', '').to_f, dpp_gap: params[:selisih_dpp].gsub('Rp', '').gsub('.', '').to_f))
        @printed_inv = @inv.process_print_inv(params, current_user)
        @flag = 3
      else
        raise @inv.errors.full_messages.inspect
      end
    else
      not_authorized
    end
  end

  #desc: untuk print invoice menjadi PDF
  def print
    @inv = PurchaseOrder.where("invoice_number='#{@inv.invoice_number}' AND is_history IS FALSE").last
    if @inv.can_print_inv?
      @inv.print_invoice_date = Time.now
      if @inv.print_inv
        PurchaseOrder.send_notifications(@inv)
        render :pdf => "#{@inv.invoice_number}",
          :disposition => 'inline',
          :layout=> 'layouts/invoice.pdf.erb',
          :template => 'order_to_payments/invoices/inv_template.pdf.erb',
          :page_size => 'A4',
          :lowquality => false
      else
        something_wrong
      end
    else
      forbidden
    end
  end

  #desc: mengirimkan invoice yg compelete untuk dijadikan early payment request
  def send_invoice_payment_request
    @update_invoice_to_payment_request = PurchaseOrder.find(params[:id])
    if @update_invoice_to_payment_request.update_is_create_payment_request_and_create_payment_request(current_user)
      if @update_invoice_to_payment_request
        flash[:notice] = "Early Payment Request has been created."
        respond_to do |format|
          format.js{
            render :js => "window.location= '#{order_to_payments_invoices_path}'"
          }
        end
      end
    end
  end

  def get_push_invoice_completed_to_api
    @results = @inv.push_invoice_to_api
    status = eval_status_res(@results)
    send_email_which_service_api_is_not_connected(status)
    respond_to do |f|
      @results = PurchaseOrder.search(params).order("po_number, created_at DESC").where("is_completed = true and is_history = false").where(:order_type => "#{INV}").accessible_by(current_ability).readonly(false).page(params[:page])
      f.js {render :layout => false, :status=>status}
    end
  end

  def find_inv_history
    @inv = PurchaseOrder.find_inv_history(params[:id]).last
    not_found if @inv.blank?
    # raise @inv
  end

  def get_inv_history
    add_breadcrumb "INV History", :order_to_payments_get_inv_history_path
    @past_inv = PurchaseOrder.order("updated_at desc").where("po_number like ? and order_type like ?", @inv.po_number, "%#{INV}%").page(params[:page]).per(5)
    not_found if @past_inv.blank?
  end

  def find_inv
    @inv = PurchaseOrder.find(params[:id])
    not_found if @inv.blank?
  end

end

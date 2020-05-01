class PaymentVouchersController < ApplicationController
  layout "main"
  before_filter :get_invoice, :only => [:new, :get_invoice_based_on_supplier, :create]
  before_filter :get_payment_voucher, :only => [:show, :print_from_empo, :print_from_supplier, :generate_xls_details_voucher, :generate_pdf_details_voucher]
  before_filter :get_current_company, :only => [:print_from_empo, :print_from_supplier]
  add_breadcrumb 'List Payment Vouchers', :payment_vouchers_path
#  load_and_authorize_resource, except: [:generate_pdf_details_voucher]

  def index
    conditions = ["is_history = FALSE"]
    params[:search].each{|param|
      conditions << "#{param[0]}::text LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @results = PaymentVoucher.where(conditions.join(' AND ')).joins(:supplier).order(default_order('payment_vouchers')).select("payment_vouchers.*, suppliers.code AS supplier_code").accessible_by(current_ability).order("payment_vouchers.created_at DESC").page params[:page]
    if (params["format"] == "xls")
      @results_all = PaymentVoucher.where(conditions.join(' AND ')).joins(:supplier).order(default_order('payment_vouchers')).select("payment_vouchers.*, suppliers.code AS supplier_code").accessible_by(current_ability).order("payment_vouchers.created_at DESC")
    end
    respond_to do |format|
      format.html
      format.js
      format.xls
    end
  end

  def generate_pdf_all_pv
      title = "PV_ALL_#{Time.new.strftime('%d-%m-%Y')}"
      @results = PaymentVoucher.where(["is_history = FALSE"].join(' AND ')).joins(:supplier).order(default_order('payment_vouchers')).select("payment_vouchers.*, suppliers.code AS supplier_code").accessible_by(current_ability).order("payment_vouchers.created_at DESC")
      render :pdf => title,
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'payment_vouchers/pv_all.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def new
    add_breadcrumb 'Generate Payment Vouchers', :new_payment_voucher_path
    @payment_vouchers = PaymentVoucher.new
  end

  def get_invoice_based_on_supplier
    render :layout => false
  end

  def generate_xls_details_voucher
    send_file @result.export_to_xls, :disposition => 'inline', :type => 'application/xls', :filename => "Payment Voucher-#{@result.voucher}.xls"
  end

  def generate_pdf_details_voucher
    @payment_voucher = PaymentVoucher.where(voucher: "#{@result.voucher}").order("created_at ASC")
    @result_details = @payment_voucher.last.payment_voucher_details
    render :pdf => "GRN-#{@result.voucher}",
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'payment_vouchers/payment_vouchers.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def create
    @payment_vouchers = PaymentVoucher.new
    unless current_user.warehouse.blank?
      payment_voucher = PaymentVoucher.save_payment_voucher(params, current_warehouse.id, current_user)
      if payment_voucher
        redirect_to payment_vouchers_path, :notice => "Successfully"
      else
        render "new"
      end
    else
      redirect_to payment_vouchers_path, :alert => "Failed, you do not have any Warehouse"
    end
  end

  def approve_invoice
    approve_invoice = PaymentVoucher.find(params[:id])
    if approve_invoice.approve_invoice_selected(current_user)
      redirect_to payment_vouchers_path, :notice => "Payment Voucher has been approved"
    else
      redirect_to payment_voucher_path(params[:id]), :alert => "Sorry, please check again."
    end
  end

  def show
    add_breadcrumb 'Details Payment Vouchers', payment_voucher_path(params[:id])
    #create form approval
    @payment_voucher = PaymentVoucher.new

    @results = @result.payment_voucher_details.filter(params).page params[:page]
  end

  def print_from_empo
    render :pdf => "#{@result.voucher}",
      :disposition => 'inline',
      :layout => 'layouts/payment.pdf.erb',
      :template => 'payment_vouchers/print_payment_voucher_empo.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def print_from_supplier
    render :pdf => "#{@result.voucher}",
      :disposition => 'inline',
      :layout => 'layouts/payment.pdf.erb',
      :template => 'payment_vouchers/print_payment_voucher_supplier.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def need_approval
  end

  private

  def get_invoice
    @results = []
    unless params[:supplier_name].blank?
      @results = PurchaseOrder.where_supplier_name(params).completed_inv_search(params).with_inv_state(:completed).get_completed_payment_voucher(false).order("purchase_orders.po_number, purchase_orders.created_at DESC").page params[:page]
    end
  end

  def get_payment_voucher
    @result = PaymentVoucher.find(params[:id])
  end
end

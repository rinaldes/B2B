class PaymentsController < ApplicationController
  layout "main"
  before_filter :find_payment, :only=>[:show, :reject, :accept, :print, :generate_pdf_details_payment, :generate_xls_details_payment]
  before_filter :get_current_company, :only => [:print]
  add_breadcrumb 'Payments', :payments_path
  load_and_authorize_resource :except=>[:search_pv, :search_dn, :search_retur, :generate_pdf_details_payment, :generate_xls_details_payment]

  def generate_xls_details_payment
    send_file @payment.export_to_xls, :disposition => 'inline', :type => 'application/xls', :filename => "Payment-#{@payment.no}.xls"
  end

  def generate_pdf_details_payment
    @payment_details = @payment.payment_details
    render :pdf => "Payment-#{@payment.no}",
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'payments/payment.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def index
    @results = Payment.filter(params).accessible_by(current_ability).order("created_at DESC").page params[:page]
  	if(params["format"] == "xls")
      @results_all = Payment.filter(params).accessible_by(current_ability).order("created_at DESC")
    end
    respond_to do |f|
      f.html
      f.js
      f.xls
    end
  end

  def show
  	@details = @payment.payment_details.order("payment_element_type ASC")
  end

  def generate_pdf_all_pay
      title = "PAY_ALL_#{Time.new.strftime('%d-%m-%Y')}"
      @results = Payment.filter(params).accessible_by(current_ability).order("created_at DESC")
      render :pdf => title,
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'payments/pay_all.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def new
  	@payment = Payment.new
    @payment.payment_details.build
  end

  def create
    @payment = Payment.create_payment(current_ability, params, current_user)
    respond_to do |f|
      f.html{render layout: false}
      f.js{
        unless @payment.errors.any?
          unless current_user.roles.first.features.where(:name => 'Approval from supplier', :regulator => 'Payment').first.nil?
            flash[:notice] = "Payment has been created"
            render :js => "window.location = '#{payments_path}'"
          else
            if @payment.can_approve?
              unless Payment.accept_payment(@payment, current_user).errors.any?
                flash[:notice] = "Payment has been created and approved"
                render :js => "window.location = '#{payments_path}'"
              else
                flash[:notice] = "Failed to approve payment, please contact administrator"
                render :js => "window.location = '#{payments_path}'"
              end
            else
              flash[:notice] = "Payment has been created"
              render :js => "window.location = '#{payments_path}'"
            end
          end
        end
      }
    end
  end

  def accept
    if @payment.can_approve?
      @accepted_payment = Payment.accept_payment(@payment, current_user)
      respond_to do |f|
        f.html{ render layout:false}
        f.js {
          unless @accepted_payment.errors.any?
            flash[:notice] = "Payment has been approved"
            render :js => "window.location = '#{payments_path}'"
          end
        }
      end
    else
      not_authorized
    end
  end

  def reject
    if @payment.can_reject?
      @rejected_payment = Payment.reject_payment(@payment, current_user)
      respond_to do |f|
        f.html{ render layout:false}
        f.js {
          unless @rejected_payment.errors.any?
            flash[:notice] = "Payment has been rejected"
            render :js => "window.location = '#{payments_path}'"
          end
        }
      end
    else
      not_authorized
    end
  end

  def print
    if @payment.approved?
      render :pdf => "#{@payment.no}",
        :disposition => 'inline',
        :layout => 'layouts/invoice.pdf.erb',
        :template => 'payments/print.pdf.erb',
        :page_size => 'A4',
        :lowquality => false
    else
      not_authorized
    end
  end

  def search_pv
    @params= params
    unless params[:supplier_name_autocomplete].blank?
      @pv_results = PaymentVoucher.with_is_approved(:approved).with_payment_state(:unused).joins(:supplier).where("suppliers.code = ? or suppliers.name = ?", params[:supplier_name_autocomplete],params[:supplier_name_autocomplete])
      unless params[:search][:detail].blank?
        @pv_results = @pv_results.where("voucher ilike ?","%#{params[:search][:detail]}%")
      end
      @pv_results = @pv_results.accessible_by(current_ability)
      @pv_results = @pv_results.page(params[:page]).per(5)
    end
  end

  def search_dn
    @params = params
    unless params[:supplier].blank?
      @dn_results = DebitNote.get_search_dn(params).accessible_by(current_ability).page(params[:page])
    end
  end

  def search_retur
    @params = params
    unless params[:supplier].blank?
      @retur_results = ReturnedProcess.get_search_retur(params).accessible_by(current_ability).page(params[:page])
    end
  end
  
  def need_approval_from_supplier
    
  end

  def need_approval
  end

  private
  def find_payment
    @payment = Payment.find(params[:id])
    not_found if @payment.blank?
  end
end

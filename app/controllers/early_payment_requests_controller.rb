class EarlyPaymentRequestsController < ApplicationController
  layout "main"
  before_filter :get_self_early_payment_request, :only => [:show_detail_bank, :new_detail_bank, :create_detail_bank, :approve, :print_early_payment_request_with_bank, :send_payment_request, :accept_payment_request, :reject_payment_request]
  before_filter :approve, :only => [:send_payment_request, :accept_payment_request, :reject_payment_request]
  before_filter :get_current_company, :only => [:print_early_payment_request_with_bank, :print]
  before_filter :get_list_early_payment_status, :only => [:index, :print]
  add_breadcrumb 'List Early Payment Request', :early_payment_requests_path
  load_and_authorize_resource

  def index
    @results_all = DeliverBank.all
    respond_to do |f|
      f.html
      f.js
      f.xls
    end
  end

  def send_payment_request
  end

  def accept_payment_request
  end

  def reject_payment_request
  end

  def generate_pdf_all_epr
      title = "EPR_ALL_#{Time.new.strftime('%d-%m-%Y')}"
      @results = DeliverBank.all
      render :pdf => title,
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'early_payment_requests/epr_all.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def approve
    flag = true
    if @epr
      if @epr.update_status_early_payment_request(params[:state_name], current_user)
        flash[:notice] = "Early Payment Request has been #{params[:state_name]}."
        respond_to do |format|
          format.js{
            render :js => "window.location= '#{early_payment_requests_path}'"
          }
        end
      else
        flag = false
      end
    else
      flag = false
    end
    if flag == false
      redirect_to early_payment_requests_path, :alert => "Early Payment Request has been #{params[:state_name]}."
    end
  end

  def show_detail_bank
    @bank = @epr.deliver_banks.first
  end

  def new_detail_bank
    @bank = DeliverBank.new
  end

  def print_early_payment_request_with_bank
    render :pdf => "EPR-INV-#{@epr.purchase_order.invoice_number}",
      :disposition => 'inline',
      :layout => 'layouts/payment.pdf.erb',
      :template => 'early_payment_requests/print_early_payment_request_with_bank.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def print
    render :pdf => "Early Payment Request",
      :disposition => 'inline',
      :layout => 'layouts/payment.pdf.erb',
      :template => 'early_payment_requests/print.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def create_detail_bank
    @bank = DeliverBank.new
    if @bank.save_detail_bank(@epr, params, current_user)
      flash[:notice] = "Successfully, Credential bank with account number has been created"
      respond_to do |format|
        format.js {
          render :js => "$('#modal-popup-bank').modal('hide'); window.location = '#{early_payment_requests_path}'"
        }
      end
    else
      render 'new_detail_bank'
    end
  end

  private

  def get_self_early_payment_request
    @epr = EarlyPaymentRequest.find(params[:id])
  end

  def get_list_early_payment_status
    @results = EarlyPaymentRequest.where(:is_history => false).search_early_payment_requests(params).accessible_by(current_ability).order("created_at DESC")#.page params[:page]
  end
end

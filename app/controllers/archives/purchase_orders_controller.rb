class Archives::PurchaseOrdersController < ApplicationController
  layout 'main'
  add_breadcrumb 'List Completed Transaction', :archives_purchase_orders_path
  load_and_authorize_resource :class=>"PurchaseOrder"

  def index
    @results = PurchaseOrder.search(params).order("created_at DESC").where("order_type = '#{PO}' AND is_completed = true AND state NOT IN (0, 1)").accessible_by(current_ability)#.readonly(false)#.page params[:page]
    if params["format"] == "xls"
      @results_all = PurchaseOrder.search(params).order("created_at DESC").where("order_type = '#{PO}' AND is_completed = true AND state NOT IN (0, 1)").accessible_by(current_ability).readonly(false)
    end
    respond_to do |f|
      f.html{}
      f.js{}
      f.xls{}
    end
  end

  def generate_pdf_all_arc
      title = "ARC_ALL_#{Time.new.strftime('%d-%m-%Y')}"
      @results = PurchaseOrder.search(params).order("created_at DESC").where('order_type = ? AND is_completed = true AND (state = 2 or state = 3)', PO).accessible_by(current_ability).readonly(false)
      render :pdf => title,
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'order_to_payments/archive/arc_all.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end
end

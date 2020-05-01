class DashboardsController < ApplicationController
  layout "main"
  before_filter :count_po_today_statuses, :only=>[:index]
  before_filter :count_new_po, :only => [:index]
  before_filter :for_sl_statistic, :only=>[:index, :get_suppliers, :get_service_level_flot_by_supplier]
  before_filter :get_all_po_status_statistic, :only=>[:index]
  before_filter :get_po_stats, :only => [:report_goods_return_note, :report_purchase_order, :report_goods_receive_notes,
                :report_goods_receive_price_confirmations, :report_invoice, :detail_report_order, :detail_report_return]
  before_filter :get_dn_stats, :only => [:report_debit_note]
  authorize_resource :class => false

  def index
    #@controller = params[:controller]
    get_po_today_status(current_user)
    @image_blast = ImageBlast.where("valid_from < now() AND valid_until >= now()")
  end

  def get_po_today_status(current_user)
    @new_po_today = PurchaseOrder.count_po_statuses_today("#{PO}",current_user)
    @new_asn_today = PurchaseOrder.count_po_statuses_today("#{ASN}",current_user)
    @new_grn_today = PurchaseOrder.count_po_statuses_today("#{GRN}",current_user)
    @unread_asn_today = PurchaseOrder.count_po_statuses_today("#{ASN}",current_user)
    @unread_grn_today = PurchaseOrder.count_po_statuses_today("#{GRN}",current_user)
    @new_inv_today = PurchaseOrder.count_po_statuses_today("#{INV}",current_user)
    @new_dn_today = DebitNote.count_dn_statuses_today(current_user)

    @po_new = PurchaseOrder.where(:order_type=> "#{PO}", :state=>0).where("po_date='#{Time.now.strftime('%Y-%m-%d')}' OR due_date='#{Time.now.strftime('%Y-%m-%d')}'")
      .accessible_by(current_ability).readonly(false).count
    @po_ontime = PurchaseOrder.where(:order_type=> "#{PO}", :state=>2).where("po_date='#{Time.now.strftime('%Y-%m-%d')}' OR due_date='#{Time.now.strftime('%Y-%m-%d')}'")
      .accessible_by(current_ability).readonly(false).count rescue 0
    @po_ontime_less = PurchaseOrder.where(:order_type=> "#{PO}", :state=>3).where("po_date='#{Time.now.strftime('%Y-%m-%d')}' OR due_date='#{Time.now.strftime('%Y-%m-%d')}'")
      .accessible_by(current_ability).readonly(false).count rescue 0
    @po_exp = PurchaseOrder.where(:order_type=> "#{PO}", :state=>6).where("po_date='#{Time.now.strftime('%Y-%m-%d')}' OR due_date='#{Time.now.strftime('%Y-%m-%d')}'")
      .accessible_by(current_ability).readonly(false).count rescue 0

    @dn_pending = DebitNote.where(state: nil).where("transaction_date='#{Time.now.strftime('%Y-%m-%d')}'").accessible_by(current_ability).readonly(false).count rescue 0
  end

  def my_notification
    conditions = []
    @notifications = Supplier.first.suppliers_notifications.where(conditions.join(' AND ')).joins(:notification).order(default_order('suppliers_notifications')).page(params[:page])
  end
  
  def get_selected_state_stats
    @po_stats = PurchaseOrder.stats_of_all_po_state("#{params[:id]}", params[:date], current_user)
    @dn_stats = DebitNote.stats_of_all_dn_state("#{params[:id]}", params[:date], current_user)
    not_found if @po_stats.blank? || @po_stats == 1
  end

  def report_purchase_order
    not_found if @stats.blank?
    respond_to do |f|
      f.json {render :json=>@stats}
    end
  end

  def get_report
    add_breadcrumb "#{params[:search][:order_type].gsub('_',' ').titleize} Report", "#"
    @order_type = params[:search][:order_type]
    if params[:search][:order_type] == "goods_return_note"
       if current_user.has_role? :superadmin
        @results = ReturnedProcess.search_report(params).order("rp_date DESC").page params[:page]
      elsif current_user.warehouse
        @results = ReturnedProcess.search_report(params, current_user).order("rp_date DESC").page params[:page]
      elsif current_user.supplier
        @results = ReturnedProcess.search_report(params, current_user).order("rp_date DESC").page params[:page]
      end
    elsif params[:search][:order_type] == "debit_notes"
      if current_user.has_role? :superadmin
        @results = DebitNote.search_report(params).order("transaction_date DESC").page params[:page]
      elsif current_user.warehouse
        @results = DebitNote.search_report(params, current_user).order("transaction_date DESC").page params[:page]
      elsif current_user.supplier
        @results = DebitNote.search_report(params, current_user).order("transaction_date DESC").page params[:page]
      end
    else
      if current_user.has_role? :superadmin
        @results = PurchaseOrder.search_report(params).order("created_at DESC").page params[:page]
      elsif current_user.warehouse
        @results = PurchaseOrder.search_report(params, current_user).order("created_at DESC").page params[:page]
      elsif current_user.supplier
        @results = PurchaseOrder.search_report(params, current_user).order("created_at DESC").page params[:page]
      end
    end
    respond_to do |f|
      f.html{}
      f.js{}
    end
  end

  def detail_report_orders
    @po = PurchaseOrder.find(params[:id])
    if @po.details_purchase_orders.count == 0
      @details = DetailsPurchaseOrder.get_and_save_po_details_from_api(@po)
      case @details
        when 2
          not_found
        when -1
          redirect_to :back, :alert => "Details have not a tax line, please check again"
        when true
          @details = @po.details_purchase_orders.order("seq ASC").page(params[:page]).per(PER_PAGE)
        else
          something_wrong
      end
    else
      @details = @po.details_purchase_orders.order("seq ASC").page(params[:page]).per(PER_PAGE)
    end
  end

  def detail_report_debit_note
    @dn = DebitNote.find(params[:id])
    @details = DebitNote.find(params[:id]).debit_notes.only_type_cr
  end

  def detail_report_return
    @retur = ReturnedProcess.find_retur(params[:id]).last
    if @retur.returned_process_details.count == 0
      @details = ReturnedProcessDetail.get_and_save_detail_retur_from_api(@retur)
      case @details
        when 2
          not_found
        when -1
          no_content
        when true
          @details = @retur.returned_process_details.order("seq ASC").page(params[:page]).per(PER_PAGE)
        else
          something_wrong
      end
    else
      @details = @retur.returned_process_details.order("seq ASC").page(params[:page]).per(PER_PAGE)
    end
  end

  def report_goods_receive_notes
    not_found if @stats.blank?
    respond_to do |f|
      f.json {render :json=>@stats}
    end
  end

  def report_goods_receive_price_confirmations
    not_found if @stats.blank?
    respond_to do |f|
      f.json {render :json=>@stats}
    end
  end

  def report_invoice
    not_found if @stats.blank?
    respond_to do |f|
      f.json {render :json=>@stats}
    end
  end

  def report_goods_return_note
    not_found if @stats.blank?
    respond_to do |f|
      f.json {render :json=>@stats}
    end
  end

  def report_debit_note
    not_found if @stats.blank?
    respond_to do |f|
      f.json {render :json=>@stats}
    end
  end

  def count_disputed_po
    arr = PurchaseOrder.count_disputed_po(current_user)
    respond_to do |f|
      f.json {render :json=>arr}
    end
  end

  def count_disputed_dn
    arr = DebitNote.count_disputed_dn(current_user)
    respond_to do |f|
      f.json {render :json=>arr}
    end
  end

  def count_po_today_statuses
    @count=PurchaseOrder.count_po_statuses("#{PO}",current_user)
  end

  def for_sl_statistic
    if params[:supplier_id].blank?
      @sl_stats =  ServiceLevelHistory.count_sl_total_per_tr(Date.today.year, current_ability)
    else
      @sl_stats =  ServiceLevelHistory.count_sl_total_per_tr(Date.today.year, params[:supplier_id].to_i)
    end
    @year = Date.today.year
=begin
    params[:supplier_id] = current_user.supplier_id if current_user.supplier.present?
    po_conditions = ["purchase_orders.created_at>'2016-08-01 00:00:00' AND order_type='#{PO}'"]
    po_conditions << "supplier_id=#{params[:supplier_id]}" if params[:supplier_id].present?
    po_lines = DetailsPurchaseOrder.where(po_conditions.join(' AND ')).joins(:purchase_order)
    grn_conditions = ["order_type='#{GRN}' AND po_number IN ('#{po_lines.map{|poline|poline.purchase_order.po_number}.join("','")}')"]
    grn_conditions << "supplier_id=#{params[:supplier_id]}" if params[:supplier_id].present?
    grn_lines = DetailsPurchaseOrder.where(grn_conditions.join(' AND ')).joins(:purchase_order)
    service_level = ServiceLevel.first
    lines = grn_lines.count/po_lines.count.to_f*service_level.sl_line
    qty = grn_lines.map(&:received_qty).sum.to_f/grn_lines.map(&:order_qty).sum.to_f*service_level.sl_qty
#    raise qty.inspect
=end
  end

  def get_suppliers
    @suppliers = PurchaseOrder.where(:warehouse_id => params[:id]).collect{|po| [po.supplier.name, po.supplier.id] }.uniq
    render :layout => false
  end

  def get_service_level_flot_by_supplier
    @data = {:sl_stats => @sl_stats, :year => @year}
    render :layout => false, :json => @data
  end

  def get_all_po_status_statistic
    @po_stats = PurchaseOrder.stats_of_all_po_state("#{PO}", Date.today.strftime("%Y%m"), current_user)
    @dn_stats = DebitNote.stats_of_all_dn_state(params[:date], current_user)
    not_found if @po_stats == 1 || @po_stats.blank?
  end

  private

  def count_grtn_today_statuses
    @count = ReturnedProcess.count_grtn_today_statuses(current_user)
  end

  def count_new_po
    @new_po = PurchaseOrder.where(:is_history => false, state: [0, 1], order_type: "#{PO}").accessible_by(current_ability).count
    @new_asn = PurchaseOrder.where(:is_history => false, asn_state: [1, 2], order_type: "#{ASN}", is_published: true).accessible_by(current_ability).count
    @new_grn = PurchaseOrder.where(:is_history => false, grn_state: [1, 2], order_type: "#{GRN}").accessible_by(current_ability).count
    @unread_asn = PurchaseOrder.count_po_statuses("#{ASN}",current_user)[:unread]
    @unread_grn = PurchaseOrder.count_po_statuses("#{GRN}",current_user)[:new].to_i
    @new_inv = PurchaseOrder.where(:is_history => false, inv_state: current_user.warehouse.present? ? 2 : 1, order_type: "#{INV}").accessible_by(current_ability).count
    @new_dn = DebitNote.only_type_in.where(:is_history => false, state: nil).filter_debit_notes(params).accessible_by(current_ability).order("cast(order_number AS integer) DESC").count
  end

  def not_found
    render :file => "#{Rails.root.join('public','404.html')}",  :status => 404
  end

  def get_po_stats
    @stats = PurchaseOrder.stats_of_all_po_state(params[:id], params[:date], current_user)
  end

  def get_dn_stats
    @stats = DebitNote.stats_of_all_dn_state(params[:date], current_user)
  end
end

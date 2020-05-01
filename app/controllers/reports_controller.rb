class ReportsController < ApplicationController
	layout "main"
	add_breadcrumb 'Reporting', "#"
	before_filter :get_current_company
	before_filter :find_retur, :only => [:returned_history_details]
	before_filter :find_grn_grpc, :only => [:on_going_dispute_details]
  authorize_resource :class => false, :except => [:on_going_dispute_details, :returned_history_details, :pending_delivery_details, :print_to_xls, :print_to_pdf, :payment_progress, :generate_xls_details_sls]

  def generate_xls_details_sls
    send_file ServiceLevelHistory.find(params[:id]).export_to_xls["path"], :disposition => 'inline', :type => 'application/xls', :filename => "SUPPLIER GROUP-#{@group.code}.xls"
  end

  def payment_progress
    add_breadcrumb 'Payment', :payment_progress_reports_path
    @results = PaymentDetail.select("invoice_number, payment_id, suppliers.code AS supplier_code, warehouse_code, invoice_due_date, invoice_date")
      .joins(payment: [:purchase_order, :supplier, :warehouse]).group("payment_id, invoice_number, suppliers.code, warehouse_code, invoice_due_date, invoice_date").accessible_by(current_ability)#.page params[:page]
  end

	def service_level_suppliers
		add_breadcrumb 'Service Level Suppliers', :service_level_suppliers_reports_path
		@results = ServiceLevelHistory.search(params).accessible_by(current_ability)#.page params[:page]
	end

	def on_going_disputes
		add_breadcrumb "On Going Disputes (#{params[:type]})", on_going_disputes_reports_path(params[:type])
		if params[:type] == "GRN"
			@results = PurchaseOrder.search_disputed_po("GRN",params).where(:is_history => false, :order_type => "#{GRN}").accessible_by(current_ability)#.page params[:page]
		elsif params[:type] == "GRPC"
			@results = PurchaseOrder.search_disputed_po("GRPC",params).where(:is_history => false, :order_type => "#{GRPC}").accessible_by(current_ability)#.page params[:page]
		end
	end

	def on_going_dispute_details
		add_breadcrumb "On Going Disputes (#{params[:type]})", on_going_disputes_reports_path(params[:type])
		add_breadcrumb "On Going Disputes Details (#{params[:type]})", on_going_dispute_details_report_path(@purchase_order, params[:type])
		_hash_type = params[:type] == "GRN" ? {:number_of => @purchase_order.grn_number, :type => GRN} : {:number_of => @purchase_order.grpc_number, :type => GRPC}
		@disputed = PurchaseOrder.get_dispute_details(params, _hash_type)
    @dispute_details = @disputed.last.details_purchase_orders.order("seq ASC").page(params[:page]).per(PER_PAGE)
	end

	def pending_deliveries
		add_breadcrumb "Pending Deliveries", pending_deliveries_reports_path
		@results = PurchaseOrder.get_asn_without_grn(params).accessible_by(current_ability)#.page params[:page]
	end

	def returned_histories
		add_breadcrumb "Returned Histories", returned_histories_reports_path
		@results = ReturnedProcess.where(:is_history => false).search_reporting(params).accessible_by(current_ability)#.page params[:page]
	end

  def account_payable
    add_breadcrumb "Account Payable", account_payable_reports_path

    CurrentPeriod.synch_now
    DebitNote.synch_debit_note_now

    cp = CurrentPeriod.last
    date = cp.cl_year.to_s + cp.cl_period.to_s

    conditions = []

    # untuk supplier, ambil yg id suppliernya sama saja
    if !current_user.supplier.nil?
      conditions << "supplier_id = #{current_user.supplier_id}"
    elsif params[:search].present? && params[:search][:supplier_code].present?
      # untuk selain supplier yg ingin search berdasarkan kode supplier
      supplier = Supplier.where("code like '%#{params[:search][:supplier_code]}%'").first
      if supplier.nil?
        @results = []
        return
      else
        conditions << "supplier_id = #{supplier.id}"
      end
    end

    @results = DebitNote
      .where("#{conditions.push("cast((to_char(transaction_date, 'YYYY')) as integer) = #{cp.cl_year.to_s} AND cast((to_char(transaction_date, 'MM')) as integer) = #{cp.cl_period.to_s}").join(" and ")}")
    @current = @results.pluck(:amount).sum
    @last_30 = DebitNote.where("#{conditions.join(" and ")} and cast((financial_year || financial_period) as integer) = ?", (date.to_i % 100) == 1 ? date.to_i - 89 : date.to_i - 1).pluck(:amount).sum
    @last_60 = DebitNote.where("#{conditions.join(" and ")} and cast((financial_year || financial_period) as integer) = ?", (date.to_i % 100) <= 2 ? date.to_i - 90 : date.to_i - 2).pluck(:amount).sum
    @last_90 = DebitNote.where("#{conditions.join(" and ")} and cast((financial_year || financial_period) as integer) < ?", (date.to_i % 100) <= 3 ? date.to_i - 91 : date.to_i - 3).pluck(:amount).sum
    @future  = DebitNote.where("#{conditions.join(" and ")} and cast((financial_year || financial_period) as integer) > ?", date.to_i).pluck(:amount).sum
  end

  def account_receivable
    add_breadcrumb "Returned Histories", account_receivable_reports_path

    CurrentPeriod.synch_now
    DebitNote.synch_debit_note_now

    cp = CurrentPeriod.last
    date = cp.dl_year.to_s + cp.dl_period.to_s

    conditions = []

    # untuk supplier, ambil yg id suppliernya sama saja
    if !current_user.supplier.nil?
      conditions << "supplier_id = #{current_user.supplier_id}"
    elsif params[:search].present? && params[:search][:supplier_code].present?
      # untuk selain supplier yg ingin search berdasarkan kode supplier
      supplier = Supplier.where("code like '%#{params[:search][:supplier_code]}%'").first
      if supplier.nil?
        @results = []
        return
			else
				conditions << "supplier_id = #{supplier.id}"
			end
		end

		@results = DebitNote.where("#{(conditions+["cast((financial_year || financial_period) as integer) = #{date.to_i}"]).join(" and ")}")
		@current = @results.pluck(:amount).sum
		@last_30 = DebitNote.where("#{conditions.join(" and ")} and cast((financial_year || financial_period) as integer) = ?", (date.to_i % 100) == 1 ? date.to_i - 89 : date.to_i - 1).pluck(:amount).sum
		@last_60 = DebitNote.where("#{conditions.join(" and ")} and cast((financial_year || financial_period) as integer) = ?", (date.to_i % 100) <= 2 ? date.to_i - 90 : date.to_i - 2).pluck(:amount).sum
		@last_90 = DebitNote.where("#{conditions.join(" and ")} and to_date(financial_year || '-' || (financial_period), 'YYYY-MM') < ?", "#{cp.dl_year.to_s}-#{sprintf('%02d', cp.dl_period-3)}-01").pluck(:amount).sum
		@future  = DebitNote.where("#{conditions.join(" and ")} and to_date(financial_year || '-' || financial_period, 'YYYY-MM') > ?", "#{cp.dl_year.to_s}-#{sprintf('%02d', cp.dl_period+1)}-01").pluck(:amount).sum
	end

	def returned_history_details
		add_breadcrumb "Returned Histories", returned_histories_reports_path
		add_breadcrumb "Returned History Details", returned_history_details_report_path(params[:id])
		@grtn_disputed = ReturnedProcess.where(:rp_number => "#{@retur.rp_number}").order("created_at ASC")
    @grtn_details = @grtn_disputed.last.returned_process_details
	end

	def print_to_xls
		case params[:from]
		when "service_level_suppliers"
			results = ServiceLevelHistory.accessible_by(current_ability).print_to_xls(params, current_ability)
			file_name = "Service Level Supplier-#{Date.today}.xls"
		when "pending_deliveries"
			results = PurchaseOrder.accessible_by(current_ability).print_to_xls(params, "pd",current_ability)
			file_name = "Pending Delivery-#{Date.today}.xls"
		when "ogd_grn"
			results = PurchaseOrder.where(:is_history => false, :order_type => "#{GRN}").accessible_by(current_ability).print_to_xls(params, "grn",current_ability)
			file_name = "On Going Delivery (GRN)-#{Date.today}.xls"
		when "ogd_grpc"
			results = PurchaseOrder.where(:is_history => false, :order_type => "#{GRPC}").accessible_by(current_ability).print_to_xls(params, "grpc",current_ability)
			file_name = "On Going Delivery (GRPC)-#{Date.today}.xls"
		when "returned_history"
			results = ReturnedProcess.accessible_by(current_ability).print_to_xls(params, current_ability)
			file_name = "Returned Histories-#{Date.today}.xls"
		end
		send_file results["path"], :disposition => 'inline', :type => 'application/xls', :filename => file_name
	end

	def pending_delivery_details
		add_breadcrumb "Pending Deliveries", pending_deliveries_reports_path
		add_breadcrumb "Pending Delivery Details", pending_delivery_details_report_path(params[:id])
		@purchase_order = PurchaseOrder.find(params[:id])
		@purchase_order_details = @purchase_order.details_purchase_orders.order("seq ASC")
	end

	def print_to_pdf
		@results, file_name = [], ""
		case params[:from]
		when "service_level_suppliers"
			@results = ServiceLevelHistory.accessible_by(current_ability).print_to_pdf(params, current_ability)
			file_name = "Service Level Supplier-#{Date.today}"
			template_name = "service_level_suppliers.pdf.erb"
			title = "Service Level Suppliers"
		when "pending_deliveries"
			@results = PurchaseOrder.accessible_by(current_ability).print_to_pdf(params, "pd",current_ability)
			file_name = "Pending Delivery-#{Date.today}"
			template_name = "pending_deliveries.pdf.erb"
			title = "Pending Delivery"
		when "ogd_grn"
			@results = PurchaseOrder.where(:is_history => false, :order_type => "#{GRN}").accessible_by(current_ability).print_to_pdf(params, "grn",current_ability)
			file_name = "On Going Delivery (GRN)-#{Date.today}"
			template_name = "on_going_disputes.pdf.erb"
			title = "On Going Dispute (#{GRN})"
		when "ogd_grpc"
			@results = PurchaseOrder.where(:is_history => false, :order_type => "#{GRPC}").accessible_by(current_ability).print_to_pdf(params, "grpc",current_ability)
			file_name = "On Going Delivery (GRPC)-#{Date.today}"
			template_name = "on_going_disputes.pdf.erb"
			title = "On Going Dispute (#{GRPC})"
		when "returned_history"
			@results = ReturnedProcess.accessible_by(current_ability).print_to_pdf(params, current_ability)
			file_name = "Returned Histories-#{Date.today}"
			template_name = "returned_histories.pdf.erb"
			title = "Returned History (#{GRN})"
		end

		render :pdf => "#{file_name}",
	      :disposition => 'inline',
	      :layout=> 'layouts/order_to_payment.pdf.erb',
	      :template => "reports/#{template_name}",
	      :page_size => 'A4',
	      :lowquality => false,
	      :title => "#{title}"
	end

	private

	def find_retur
		@retur = ReturnedProcess.find(params[:id])
	end

	def find_grn_grpc
		@purchase_order = PurchaseOrder.find(params[:id])
	end
end

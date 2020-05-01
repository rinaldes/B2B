class OrderToPayments::GoodsReceiveNotesController < ApplicationController
  layout 'main'
  before_filter :find_grn, :only=>[:show, :new_dispute_grn, :new_revise_dispute_grn, :accept_grn, :create_revise_dispute_grn, :create_dispute_grn, :get_grn_details, :generate_xls_details_grn, :generate_pdf_details_grn]
  before_filter :find_grn_history, :only=>[:get_grn_history]
  before_filter :get_grn_details, :only=>[:show]
  before_filter :get_grn_serials, :only=>[:show_grn_serial]
  add_breadcrumb "Goods Receive Notes", :order_to_payments_goods_receive_notes_path
  load_and_authorize_resource :class => "PurchaseOrder"

  def index
    @results = PurchaseOrder.search(params).order("created_at DESC").where("is_completed = true and is_history = false AND grn_state != 5").where(:order_type => "#{GRN}").accessible_by(current_ability).readonly(false)
    unless params["format"] == "xls"
      @results = @results
    end

    respond_to do |format|
      format.html
      format.js
      format.xls
    end
  end

  def show
    add_breadcrumb "GRN Detail", :order_to_payments_goods_receive_note_path
    @grn_accept = PurchaseOrder.new
    @grn.read_grn if @grn.can_read_grn?
    if @grn.grn_rev? || @grn.grn_dispute?
      @f_details = @grn.details_purchase_orders.order("seq ASC").where("COALESCE(remark, '') != ''")
      #check jika smua remark tidak diisi atau tidak
      if @f_details.count == 0
        @details = @grn.details_purchase_orders.order("seq ASC")
      else
        #hanya menampilkan remark" yang diisi
        @details = @f_details
      end
    else
      @details = @grn.details_purchase_orders.order("seq ASC")
    end
  end

  def show_grn_serial
    @grn = PurchaseOrder.find(params[:id])
    @serials = @grn.stock_serial_links
  end

  def generate_xls_details_grn
    send_file @grn.export_to_xls, :disposition => 'inline', :type => 'application/xls', :filename => "GRN-#{@grn.grn_number}.xls"
  end

  def generate_pdf_details_grn
    @grn_disputed = PurchaseOrder.where(:grn_number => "#{@grn.grn_number}", :order_type => "#{GRN}").where("grn_state in (3,4,5)").order("created_at ASC")
    @grn_details = @grn_disputed.last.details_purchase_orders.order("seq ASC")
    render :pdf => "GRN-#{@grn.grn_number}",
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'order_to_payments/goods_receive_notes/grn.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def generate_pdf_all_grn
      title = "GRN_ALL_#{Time.new.strftime('%d-%m-%Y')}"
      @results = PurchaseOrder.search(params).order("created_at DESC").where("is_completed = true and is_history = false ").where(:order_type => "#{GRN}").accessible_by(current_ability).readonly(false)
      render :pdf => title,
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'order_to_payments/goods_receive_notes/grn_all.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  #desc: Accepted GRN logic
  def accept_grn
    @grn_accept = PurchaseOrder.new

    if (GeneralSetting.where(:desc => "Last GRN Approval").first.value == "Customer" && !current_user.supplier.nil? rescue false)
      if @grn.can_pending_grn?
        @grn.user_id = current_user.id
        pending_po = @grn.pending_grn
        redirect_to order_to_payments_goods_receive_notes_path, :notice=> "GRN has been Accepted."
      else
       not_authorized
      end
    elsif @grn.can_accept_grn?
      accepted_po = PurchaseOrder.accept_grn(@grn, params, current_user)
      if accepted_po
        redirect_to order_to_payments_goods_receive_notes_path, :notice=> "GRN has been Accepted."
      else
        flash[:error]="An error has occured when accepting GRN, please try again"
        redirect_to order_to_payments_goods_receive_note_path(@grn.id)
      end
    else
     not_authorized
    end
  end

  def new_dispute_grn
    if @grn.can_raise_dispute_grn?
     @grn_dispute = PurchaseOrder.new
     @grn_dispute.user_id = current_user.id
     @grn_dispute.details_purchase_orders.build
     if @grn.grn_rev?
       @details=@grn.details_purchase_orders.where("COALESCE(remark, '') != ''").order("seq ASC")
     else
       @details=@grn.details_purchase_orders.order("seq ASC")
     end
    else
      not_authorized
    end
  end

  def max_level_and_round?(po, type, selector)
    case type
    when GRN
      transaction_type = "GRN"
      return false if po.grn_state != 3 && po.grn_state != 4
    when GRPC
      transaction_type = "GRPC"
      return false if po.grpc_state != 3 && po.grpc_state != 4
    when DN
      transaction_type = "Debit Note"
      return false if po.state != 1 && po.state != 2
    when RP
      transaction_type = "Return Process"
      return false if po.state != 4 && po.state != 5
    end
    setting = UserLevelDispute.where("user_id = ? and transaction_type='#{transaction_type}'", current_user.id).joins(:dispute_setting).first
    # raise (PurchaseOrder.where("po_number='#{po.po_number}' AND order_type='#{GRN}' AND user_id=#{current_user.id}").count >= setting.dispute_setting.max_round-1).inspect


    # jika tidak ada settingan maka eskalasi tidak terjadi
    return false if setting.nil?

    # user level di bawah level yang diperbolehkan untuk approve

    # dispute/revisi melebihi batas putaran yang diperbolehkan
    # (asumsi setiap putaran punya 2 record).
    # 1 putaran = dispute -> rejected
    # 2 putaran = dispute -> rejected -> dispute -> rejected
    # selector digunakan untuk mengambil record yg disputed
#    raise PurchaseOrder.where("po_number='#{po.po_number}' AND order_type='#{GRN}' AND user_id=#{current_user.id}").count.inspect
    last_grn_approval = GeneralSetting.find_by_desc("Last GRN Approval").value
    role_name = current_user.roles.first.parent.name
    if last_grn_approval == 'Supplier' && role_name == 'supplier' || last_grn_approval == 'Customer' && role_name == 'customer'
      return true if po.user_level >= UserLevelDispute.where("dispute_setting_id=#{DisputeSetting.find_by_transaction_type('GRN').id}").map(&:level).max && PurchaseOrder.where("po_number='#{po.po_number}' AND order_type='#{GRN}' AND user_id=#{current_user.id}").count >= setting.dispute_setting.max_round-1
    end

    time = 1.hour # default set ke jam
    if setting.dispute_setting.time_type == "Day"
      time = 1.day
    end

    # Jika update terakhir melebihi waktu eskalasi, maka tingkatkan
    # level user yang bisa mengapprove sebanyak 1 tingkat
#    return true if po.user_level >= UserLevelDispute.where("dispute_setting_id=#{DisputeSetting.find_by_transaction_type('GRN').id}").map(&:level).max && ((Time.now - po.updated_at) / time).round >= setting.dispute_setting.max_count

    return false
  end


  def rescue_accept_grn
    accepted_po = PurchaseOrder.accept_grn(@grn, params, current_user)
    if accepted_po
      return redirect_to order_to_payments_goods_receive_notes_path, :notice=> "GRN has been Accepted."
    else
      flash[:error]="An error has occured when accepting GRN, please try again"
      return redirect_to order_to_payments_goods_receive_note_path(@grn.id)
    end
  end

  #desc: membuat dispute GRN dan save GRN menjadi draft
  def create_dispute_grn
    #return rescue_accept_grn if max_level_and_round?(@grn, GRN, :grn_dispute_flow_selector)
    if @grn.can_raise_dispute_grn?
      if params[:save_grn]
        @grn.insert_details_grn_or_grpc params[:purchase_order]
        if @grn.update_attributes(params[:purchase_order])
          @grn_dispute = @grn
          details = @grn_dispute.details_purchase_orders.where("COALESCE(remark, '') != ''").order("seq ASC").page(params[:page]).per(PER_PAGE)
          if details.count == 0
            @details = @grn_dispute.details_purchase_orders.order("seq ASC").page(params[:page]).per(PER_PAGE)
          else
            @details = details
          end
          @message = "GRN is now saved."
        else
          @grn = false
        end
      elsif params[:dispute_grn]
        #check detail remark
        @_arr_valid_remark = []
        params[:purchase_order][:details_purchase_orders_attributes].each do |k, v|
          if (v["received_qty"].to_f != v["dispute_qty"].to_f && v["remark"].blank?)
            @_arr_valid_remark << "$('#span_remark_#{params[:ids][k]}').addClass('error')"
          end
        end

        if params[:purchase_order][:po_remark].present? && @_arr_valid_remark.blank?
          @grn_dispute=PurchaseOrder.create_disputed_grn(@grn,params,current_user)
          if @grn_dispute
            details=@grn_dispute.details_purchase_orders.where("COALESCE(remark, '') != ''").order("seq ASC").page(params[:page]).per(PER_PAGE)
            if details.count == 0
              @details = @grn_dispute.details_purchase_orders.order("seq ASC").page(params[:page]).per(PER_PAGE)
            else
              @details = details
            end
            @message = "GRN is disputed!"
          end
        else
          @_arr_valid_remark
          @message = "Please, fill remark when dispute #{GRN}"
        end
      elsif params[:cancel]
        if @grn.grn_rev?
          details=@grn_dispute.details_purchase_orders.where("COALESCE(remark, '') != ''").order("seq ASC").page(params[:page]).per(PER_PAGE)
          if details.count == 0
            @details = @grn_dispute.details_purchase_orders.order("seq ASC").page(params[:page]).per(PER_PAGE)
          else
            @details = details
          end
        else
          @details=@grn.details_purchase_orders.order("seq ASC").page(params[:page]).per(PER_PAGE)
        end
      end
    else
      not_authorized
    end
    @grn_accept = PurchaseOrder.new
  end

  def new_revise_dispute_grn
    if @grn.can_resolve_grn?
      @grn_revise = PurchaseOrder.new
      @grn_revise.user_id = current_user.id
      @grn_revise.details_purchase_orders.build
      details = @grn.details_purchase_orders.where("COALESCE(remark, '') != ''").order("seq ASC").page(params[:page]).per(PER_PAGE)
      if details.count == 0
        @details = @grn.details_purchase_orders.order("seq ASC").page(params[:page]).per(PER_PAGE)
      else
        @details = details
      end
    else
      not_authorized
    end
  end

  #desc: membuat revise GRN
  def create_revise_dispute_grn
    #return rescue_accept_grn if max_level_and_round?(@grn, GRN, :grn_dispute_flow_selector)
    if @grn.can_resolve_grn?
      if params[:revise_grn]

        #check detail remark
        @_arr_valid_remark = []
        params[:purchase_order][:details_purchase_orders_attributes].each do |k, v|
          #if v[:remark].blank?
          #  @_arr_valid_remark << "$('#span_remark_#{params[:ids][k]}').addClass('error')"
          #end
        end

        if params[:purchase_order][:po_remark].present? && @_arr_valid_remark.blank?
          @grn_revise = PurchaseOrder.create_revised_grn(@grn,params,current_user)
          if @grn_revise
            details = @grn_revise.details_purchase_orders.where("COALESCE(remark, '') != ''").order("seq ASC").page(params[:page]).per(PER_PAGE)
            if details.count == 0
              @details = @grn_revise.details_purchase_orders.order("seq ASC").page(params[:page]).per(PER_PAGE)
            else
              @details = details
            end
            @message = "GRN is revised!"
          end
        else
          @_arr_valid_remark
          @message = "Please, fill remark when Revise #{GRN}"
        end
      elsif params[:cancel]
        details = @grn.details_purchase_orders.where("COALESCE(remark, '') != ''").order("seq ASC").page(params[:page]).per(PER_PAGE)
        if details.count == 0
          @details = @grn.details_purchase_orders.order("seq ASC").page(params[:page]).per(PER_PAGE)
        else
          @details = details
        end
      end
    else
      not_authorized
    end
    @grn_accept = PurchaseOrder.new
  end

  #desc: menampilkan history GRN
  def get_grn_history
    add_breadcrumb "GRN History", :order_to_payments_get_grn_history_path
    @past_grn = PurchaseOrder
        .order("updated_at desc")
        .where("grn_number like ? and order_type like ?", "%#{@grn.grn_number}%", "%#{GRN}%")
        .page(params[:page])
        .per(params[:row] ? params[:row] : 5)
    not_found if @past_grn.blank?
  end

  #desc : Synch GRN ke API
  def synch_grn_now
    @results = PurchaseOrder.synch_grn_now
    status = eval_status_res(@results)
    send_email_which_service_api_is_not_connected(status)
    respond_to do |f|
      @back_to_index = "#{order_to_payments_goods_receive_notes_path}"
      f.js {render :layout => false, :status=>status}
    end
  end

  private

  def find_grn
    @grn = PurchaseOrder.find_order_type(params[:id],"#{GRN}").last
    not_found if @grn.blank?
  end

  def find_grn_history
    @grn = PurchaseOrder.find_grn_history(params[:id]).last
    not_found if @grn.blank?
  end

  def get_grn_details
    if @grn.details_purchase_orders.count == 0 #< @grn.total_line_qty.to_i
      @details = DetailsPurchaseOrder.get_and_save_po_details_from_api(@grn)
      case @details
        when 1
          not_found
        when 2
          no_content
        when true
          @details = @grn.details_purchase_orders.order("seq ASC").page(params[:page]).per(PER_PAGE)
        when -1
          redirect_to :back, :alert => "Details have not a tax line, please check again"
        else
          something_wrong
      end
    else
      @details=@grn.details_purchase_orders.order("seq ASC").page(params[:page]).per(PER_PAGE)
    end
  end

  def get_grn_serials
    @grn = PurchaseOrder.find(params[:id])
    if @grn.stock_serial_links.count == 0
      @serials = StockSerialLink.get_and_save_grn_serials_from_api(@grn)
      case @serials
        when 1
          not_found
        when 2
          no_content
        when true
          @serials = @grn.stock_serial_links.order("seq ASC").page(params[:page]).per(PER_PAGE)
        else
          something_wrong
      end
    else
      @serials=@grn.stock_serial_links.order("seq ASC").page(params[:page]).per(PER_PAGE)
    end
  end
end

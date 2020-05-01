class OrderToPayments::GoodsReceivePriceConfirmationsController < ApplicationController
  layout 'main'
  add_breadcrumb "Goods Receive Price Confirmations", :order_to_payments_goods_receive_price_confirmations_path
  before_filter :find_grpc, :only=>[:show,:new_dispute_grpc, :new_revise_dispute_grpc, :accept_grpc, :create_dispute_grpc,:create_revise_disputed_grpc,:generate_xls_details_grpc,:generate_pdf_details_grpc]
  before_filter :find_grpc_history, :only=>[:get_grpc_history]
  load_and_authorize_resource :class=>"PurchaseOrder"

  def index
     @results = PurchaseOrder.search(params).order("created_at DESC").where("is_completed = true and is_history = false AND grpc_state != 5").where(:order_type => "#{GRPC}").accessible_by(current_ability)
      .readonly(false)#.page(params[:page])
     if (params["format"]=="xls")
       @results_all = PurchaseOrder.search(params).order("created_at DESC").where("is_completed = true and is_history = false").where(:order_type => "#{GRPC}").accessible_by(current_ability).readonly(false)
     end
     respond_to do |format|
      format.html
      format.js
      format.xls
     end
  end

  def generate_xls_details_grpc
    send_file @grpc.export_to_xls, :disposition => 'inline', :type => 'application/xls', :filename => "GRPC-#{@grpc.grpc_number}.xls"
  end

  def generate_pdf_details_grpc
    @grpc_disputed = PurchaseOrder.where(:grpc_number => "#{@grpc.grpc_number}", :order_type => "#{GRPC}").where("grpc_state in (3,4,5)").order("created_at ASC")
    @grpc_details = @grpc.details_purchase_orders.order("seq ASC")
    render :pdf => "GRPC-#{@grpc.grpc_number}",
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'order_to_payments/goods_receive_price_confirmations/grpc.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def generate_pdf_all_grpc
      title = "GRPC_ALL_#{Time.new.strftime('%d-%m-%Y')}"
       @results = PurchaseOrder.search(params).order("created_at DESC").where("is_completed = true and is_history = false").where(:order_type => "#{GRPC}").accessible_by(current_ability).readonly(false)
      render :pdf => title,
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'order_to_payments/goods_receive_price_confirmations/grpc_all.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def show
    add_breadcrumb "GRPC Detail", :order_to_payments_goods_receive_price_confirmation_path
    @grpc_accept = PurchaseOrder.new
    @grpc.read_grpc if @grpc.can_read_grpc?
    if @grpc.grpc_rev? || @grpc.grpc_dispute?
      @f_details = @grpc.details_purchase_orders.order("seq ASC").where("COALESCE(remark, '') != ''").page(params[:page]).per(PER_PAGE)
      #check jika smua remark tidak diisi atau tidak
      if @f_details.count == 0
        @details = @grpc.details_purchase_orders.order("seq ASC").page(params[:page]).per(PER_PAGE)
      else
        #hanya menampilkan remark" yang diisi
        @details = @f_details
      end
    else
      @details = @grpc.details_purchase_orders.order("seq ASC").page(params[:page]).per(PER_PAGE)
    end

  end

  #desc: accept GRPC
  def accept_grpc
    if (GeneralSetting.where(:desc => "Last GRPC Approval").first.value == "Customer" && !current_user.supplier.nil? rescue false)
      if @grpc.can_pending_grpc?
        pending_po = PurchaseOrder.pending_grpc(@grpc,params,current_user)
        redirect_to order_to_payments_goods_receive_price_confirmations_path, :notice=> "GRPC has been Accepted."
      else
       not_authorized
      end
    elsif @grpc.can_accept_grpc?
      @accepted_grpc = PurchaseOrder.accept_grpc(@grpc,params,current_user)
      if @accepted_grpc
        redirect_to order_to_payments_goods_receive_price_confirmations_path, :notice=> "GRPC accepted"
      else
        render "show", :error=>"It is not possible to accept this GRPC now"
        redirect_to order_to_payments_goods_receive_price_confirmation_path(@grpc.id)
      end
    else
      not_authorized
    end
  end

  def new_dispute_grpc
    if @grpc.can_raise_dispute_grpc?
  	  @grpc_dispute = PurchaseOrder.new
      @grpc_dispute.user_id = current_user.id
  	  @grpc_dispute.details_purchase_orders.build
      if @grpc.grpc_rev?
        @details=@grpc.details_purchase_orders.where("COALESCE(remark, '') != ''").order("seq ASC")
      else
        @details=@grpc.details_purchase_orders.order("seq ASC")
      end
    else
      not_authorized
    end
  end

  #desc : membuat dispute GRPC, save GRPC menjadi draft dan cancel GRPC
  def create_dispute_grpc
    if @grpc.can_raise_dispute_grpc?
    	if params[:save_grpc]
    		@grpc.insert_details_grn_or_grpc(params[:purchase_order])
    		if @grpc.update_attributes(params[:purchase_order])
    		  @grpc_dispute = @grpc
          details = @grpc_dispute.details_purchase_orders.where("COALESCE(remark, '') != ''").order("seq ASC").page(params[:page]).per(PER_PAGE)
          if details.count == 0
            @details = @grpc_dispute.details_purchase_orders.order("seq ASC").page(params[:page]).per(PER_PAGE)
          else
            @details = details
          end
    		  @message = "GRPC is now saved."
    		else
    			@grpc_dispute = false
    		end
      elsif params[:dispute_grpc]
        #check detail remark
        @_arr_valid_remark = []
        params[:purchase_order][:details_purchase_orders_attributes].each do |k, v|
          if (v["item_price"].to_f != v["dispute_price"].to_f) && v["remark"].blank?
            @_arr_valid_remark << "$('#span_remark_#{params[:ids][k]}').addClass('error')"
          end
        end

        if params[:purchase_order][:po_remark].present? && @_arr_valid_remark.blank?
          @grpc_dispute = PurchaseOrder.create_dispute_grpc(@grpc,params,current_user)
          if @grpc_dispute
            details=@grpc_dispute.details_purchase_orders.where("COALESCE(remark, '') != ''").order("seq ASC").page(params[:page]).per(PER_PAGE)
            if details.count == 0
              @details = @grpc_dispute.details_purchase_orders.order("seq ASC").page(params[:page]).per(PER_PAGE)
            else
              @details = details
            end
            @message = "GRPC is now disputed"
          end
        else
          @_arr_valid_remark
          @message = "Please, fill remark when dispute #{GRPC}"
        end

        #unless params[:purchase_order][:po_remark].blank?
        #  @grpc_dispute = PurchaseOrder.create_dispute_grpc(@grpc,params,current_user)
        #  if @grpc_dispute
        #  	@details = @grpc_dispute.details_purchase_orders.order("seq ASC").page(params[:page]).per(PER_PAGE)
        #    @message = "GRPC is now disputed"
        #  end
        #else
        #  @message = "Please, fill remark when Dispute #{GRPC}"
        #end
      elsif params[:cancel]
        if @grpc.grpc_rev?
          details = @grpc.details_purchase_orders.where("COALESCE(remark, '') != ''").order("seq ASC").page(params[:page]).per(PER_PAGE)
          if details.count == 0
            @details = @grpc.details_purchase_orders.order("seq ASC").page(params[:page]).per(PER_PAGE)
          else
            @details = details
          end
        else
          @details = @grpc.details_purchase_orders.order("seq ASC").page(params[:page]).per(PER_PAGE)
        end
    	end
    else
      not_authorized
    end
    @grpc_accept = PurchaseOrder.new
  end

  def new_revise_dispute_grpc
  	if @grpc.can_revise_grpc?
  	  @grpc_revise = PurchaseOrder.new
      @grpc_revise.user_id = current_user.id
  	  @grpc_revise.details_purchase_orders.build
      details = @grpc.details_purchase_orders.where("COALESCE(remark, '') != ''").order("seq ASC").page(params[:page]).per(PER_PAGE)
      if details.count == 0
        @details = @grpc.details_purchase_orders.order("seq ASC").page(params[:page]).per(PER_PAGE)
      else
        @details = details
      end
    else
      not_authorized
    end
  end

  #desc: membuat revise GRPC dan cancel logic
  def create_revise_disputed_grpc
  	if @grpc.can_revise_grpc?
      if params[:revise_grpc]

        #check detail remark
        @_arr_valid_remark = []
        params[:purchase_order][:details_purchase_orders_attributes].each do |k, v|
          if v[:remark].blank?
            @_arr_valid_remark << "$('#span_remark_#{params[:ids][k]}').addClass('error')"
          end
        end

        if params[:purchase_order][:po_remark].present? && @_arr_valid_remark.blank?
          @grpc_revise = PurchaseOrder.create_revised_grpc(@grpc,params,current_user)
          if @grpc_revise
            details = @grpc_revise.details_purchase_orders.where("COALESCE(remark, '') != ''").order("seq ASC").page(params[:page]).per(PER_PAGE)
            if details.count == 0
              @details = @grpc_revise.details_purchase_orders.order("seq ASC").page(params[:page]).per(PER_PAGE)
            else
              @details = details
            end
            @message = "GRPC is revised!"
          end
        else
          @_arr_valid_remark
          @message = "Please, fill remark when Revise #{GRPC}"
        end

        #unless params[:purchase_order][:po_remark].blank?
      	#  @grpc_revise = PurchaseOrder.create_revised_grpc(@grpc,params,current_user)
      	#  if @grpc_revise
      	#    @details = @grpc_revise.details_purchase_orders.order("seq asc").page(params[:page]).per(PER_PAGE)
      	#    @message = "GRPC is now revised"
      	#  end
        #else
        #  @message = "Please, fill remark when Revise #{GRPC}"
        #end

    	elsif [:cancel]
        details = @grpc.details_purchase_orders.where("COALESCE(remark, '') != ''").order("seq ASC").page(params[:page]).per(PER_PAGE)
        if details.count == 0
          @details = @grpc.details_purchase_orders.order("seq ASC").page(params[:page]).per(PER_PAGE)
        else
          @details = details
        end
    	end
    else
      not_authorized
    end
    @grpc_accept = PurchaseOrder.new
  end

  #desc: menampilkan history GRPC
  def get_grpc_history
    add_breadcrumb "GRPC History", :order_to_payments_get_grpc_history_path
    @past_grpc = PurchaseOrder
        .order("updated_at desc")
        .where("grpc_number like ? and order_type like ?", "%#{@grpc.grpc_number}%", "%#{GRPC}%")
        .page(params[:page])
        .per(params[:row] ? params[:row] : 5)
    not_found if @past_grpc.blank?
  end

  private
  def find_grpc
  	@grpc = PurchaseOrder.find_order_type(params[:id],"#{GRPC}").last
  	not_found if @grpc.blank?
  end

  def find_grpc_history
    @grpc = PurchaseOrder.find_grpc_history(params[:id]).last
    not_found if @grpc.blank?
  end
end

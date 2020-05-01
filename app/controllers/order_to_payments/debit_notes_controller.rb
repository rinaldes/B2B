class OrderToPayments::DebitNotesController < ApplicationController
  layout 'main'
  before_filter :get_self_debit_note, :only => [:show, :get_take_action, :get_count_revision, :get_dispute_debit_note, :get_accept_debit_note, :get_revision_debit_note, :get_reject_debit_note, :new_dispute_dn,
    :synch_debit_note_detail, :create_dispute_dn, :new_revise_dispute_dn, :create_revise_dispute_dn, :accept_dn, :generate_xls_details_dn, :generate_pdf_details_dn]
  before_filter :get_take_action, :only => [:get_dispute_debit_note, :get_accept_debit_note, :get_revision_debit_note, :get_reject_debit_note, :accept_dn]
  before_filter :get_count_revision, :only => [:show]
  before_filter :get_debit_notes, :only => [:index, :print]
  before_filter :get_current_company, :only => [:print]
  before_filter :find_dn_history, :only => [:get_dn_history]
  add_breadcrumb 'List Debit Notes Voucher', :order_to_payments_debit_notes_path
#  load_and_authorize_resource :class=>"DebitNote"
  def index
    if (params["format"]=="xls")
      @results_all = DebitNote.only_type_in.where("state != 3").where(:is_history => false).filter_debit_notes(params).accessible_by(current_ability).order("cast(order_number AS integer) DESC")
    end
    respond_to do |format|
      format.html
      format.js
      format.xls
     end
  end

  def show
    add_breadcrumb 'Debit Note Detail', order_to_payments_debit_note_path(params[:id])
    @details = DebitNote.find(params[:id]).debit_note_lines
    @dn_grouped = DebitNote.where("reference='#{@debit_note.reference}' AND is_history IS FALSE").order("transaction_date ASC")
    if @debit_note.disputed?
      @f_details = @debit_note.debit_note_lines.order("sol_line_seq ASC").where("COALESCE(remark, '') != ''")
      #check jika smua remark tidak diisi atau tidak
      if @f_details.count == 0
        @details = @debit_note.debit_note_lines.order("sol_line_seq ASC")
      else
        #hanya menampilkan remark" yang diisi
        @details = @f_details
      end
    else
      @details = @debit_note.debit_note_lines.order("sol_line_seq ASC")
    end
  end

  def generate_xls_details_dn
    send_file @debit_note.export_to_xls, :disposition => 'inline', :type => 'application/xls', :filename => "DN-#{@debit_note.order_number}.xls"
  end

  def generate_pdf_details_dn
    @debit_note_disputed = DebitNote.where(:order_number => "#{@debit_note.order_number}").order("created_at ASC")
    @debit_note_details = @debit_note_disputed.last.debit_note_lines.order("sol_line_seq ASC")
    render :pdf => "DN-#{@debit_note.order_number}",
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'order_to_payments/debit_notes/dn.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def generate_pdf_all_dn
      title = "DN_ALL_#{Time.new.strftime('%d-%m-%Y')}"
      @results = DebitNote.only_type_in.where(:is_history => false).filter_debit_notes(params).accessible_by(current_ability).order("created_at DESC")
      render :pdf => title,
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'order_to_payments/debit_notes/dn_all.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  #desc: print debit note
  def print
    render :pdf => "Debit Notes",
      :disposition => 'inline',
      :layout => 'layouts/payment.pdf.erb',
      :template => 'order_to_payments/debit_notes/print.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  #dsc: synch debit note ke API dengan type IN
  def synch
    result = DebitNote.synch_debit_note_now
    status = eval_status_res(result)
    send_email_which_service_api_is_not_connected(status)
    respond_to do |f|
      @back_to_index = "#{order_to_payments_debit_notes_path}"
      f.js {render :layout => false, :status => status}
    end
  end

  #desc: synch data debit note ke API yang bertype CR
  def synch_new_payment_debit_note
    result = @debit_note.synch_debit_note_details(current_user)
    status = eval_status_res(result)
    send_email_which_service_api_is_not_connected(status)
    respond_to do |f|
      @status = status
      f.js {render :layout => false, :status => status}
    end
  end

  #desc: dispute debitnote
  def get_dispute_debit_note
  end

  #desc: accepted debitnote
  def get_accept_debit_note
  end

  #revision debitnote
  def get_revision_debit_note
  end

  def max_level_and_round?(po, type, selector)
    transaction_type = "Debit Note"
    return false if po.state != 1 && po.state != 2
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

  def create_dispute_dn
#    return rescue_accept_grn if max_level_and_round?(@debit_note, GRN, :grn_dispute_flow_selector)
    @dn_remark = params[:debit_note][:dn_remark]
    if params[:save_grn]
      #check detail remark
      @_arr_valid_remark = []
      params[:debit_note][:debit_note_lines_attributes].each do |k, v|
        if (v["sol_shipped_qty"].to_f != v["dispute_qty"].to_f && v["remark"].blank?)
          @_arr_valid_remark << "$('#span_remark_#{params[:ids][k]}').addClass('error')"
        end
      end
      if params[:debit_note][:dn_remark].present? && @_arr_valid_remark.blank?
        @dn_dispute=DebitNote.create_disputed_dn(@debit_note,params,current_user)
        if @dn_dispute
          details=@dn_dispute.debit_note_lines.where("COALESCE(remark, '') != ''").order("sol_line_seq ASC").page(params[:page]).per(PER_PAGE)
          if details.count == 0
            @details = @dn_dispute.debit_note_lines.order("sol_line_seq ASC").page(params[:page]).per(PER_PAGE)
          else
            @details = details
          end
          @message = "DN is now saved"
        end
      else
        @_arr_valid_remark
        @message = "Please, fill remark when dispute #{GRN}"
      end
    elsif params[:dispute_dn]
      #check detail remark
      @_arr_valid_remark = []
      params[:debit_note][:debit_note_lines_attributes].each do |k, v|
        if (v["sol_shipped_qty"].to_f != v["dispute_qty"].to_f && v["remark"].blank?)
          @_arr_valid_remark << "$('#span_remark_#{params[:ids][k]}').addClass('error')"
        end
      end
      if params[:debit_note][:dn_remark].present? && @_arr_valid_remark.blank?
        @dn_dispute=DebitNote.create_disputed_dn(@debit_note,params,current_user)
        if @dn_dispute
          details=@dn_dispute.debit_note_lines.where("COALESCE(remark, '') != ''").order("sol_line_seq ASC").page(params[:page]).per(PER_PAGE)
          if details.count == 0
            @details = @dn_dispute.debit_note_lines.order("sol_line_seq ASC").page(params[:page]).per(PER_PAGE)
          else
            @details = details
          end
          @message = "DN is disputed!"
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
    @grn_accept = PurchaseOrder.new
  end

  #reject debit note
  def get_reject_debit_note
  end

  def new_dispute_dn
    #if @debit_note.can_raise_dispute_dn?
     @dn_dispute = DebitNote.new
     @dn_dispute.user_id = current_user.id
     @dn_dispute.debit_note_lines.build
     @details = @debit_note.debit_note_lines.order("sol_line_seq ASC")
    #else
    #  not_authorized
    #end
  end

  #desc : fungsi di bawah ini untuk smua approval debitnote di atas
  def get_take_action
    params[:from_action] = 'accept' if params[:from_action].blank?
    result = @debit_note.take_action(params,current_user)#create_disputed_dn(@debit_note,params,current_user)
    _errors = []
    if result
      redirect_to order_to_payments_debit_notes_path, :notice => "Debit Note has been #{change_words(params[:from_action])}"
    else
      _errors << "Debit Note is not #{params[:from_action].camelize}"
      _after_slice = @debit_note.errors.full_messages.first.downcase
      _after_slice.slice! "dn remark "
      _errors << _after_slice.camelize
      flash[:alert] = _errors.join(" : ")
      #render "show"
      redirect_to order_to_payments_debit_note_path(params[:id])
    end
  end

  def accept_dn
  end

  def new_revise_dispute_dn
#    if @debit_note.can_resolve_grn?
      @dn_revise = DebitNote.new
      @dn_revise.user_id = current_user.id
      @dn_revise.debit_note_lines.build
      details = @debit_note.debit_note_lines.where("COALESCE(remark, '') != ''").order("sol_line_seq ASC").page(params[:page]).per(PER_PAGE)
      if details.count == 0
        @details = @debit_note.debit_note_lines.order("sol_line_seq ASC").page(params[:page]).per(PER_PAGE)
      else
        @details = details
      end
 #   else
  #    not_authorized
   # end
  end

  #desc: membuat revise GRN
  def create_revise_dispute_dn
#    return rescue_accept_grn if max_level_and_round?(@grn, GRN, :grn_dispute_flow_selector)
#    if @debit_note.can_resolve_grn?
      if params[:revise_dn]

        #check detail remark
        @_arr_valid_remark = []
        params[:debit_note][:debit_note_lines_attributes].each do |k, v|
          if v[:remark].blank?
            @_arr_valid_remark << "$('#span_remark_#{params[:ids][k]}').addClass('error')"
          end
        end

        if params[:debit_note][:dn_remark].present? && @_arr_valid_remark.blank?
          @dn_revise = DebitNote.create_revised_dn(@debit_note,params,current_user)
          if @dn_revise
            details = @dn_revise.debit_note_lines.where("COALESCE(remark, '') != ''").order("sol_line_seq ASC").page(params[:page]).per(PER_PAGE)
            if details.count == 0
              @details = @dn_revise.debit_note_lines.order("sol_line_seq ASC").page(params[:page]).per(PER_PAGE)
            else
              @details = details
            end
            @message = "Debit Note is revised!"
          end
        else
          @_arr_valid_remark
          @message = "Please, fill remark when Revise #{GRN}"
        end
      elsif params[:cancel]
        details = @debit_note.debit_note_lines.where("COALESCE(remark, '') != ''").order("sol_line_seq ASC").page(params[:page]).per(PER_PAGE)
        if details.count == 0
          @details = @debit_note.debit_note_lines.order("sol_line_seq ASC").page(params[:page]).per(PER_PAGE)
        else
          @details = details
        end
      end
#    else
     # not_authorized
    #end
    @dn_accept = DebitNote.new
  end

  def find_dn_history
    @debit_note = DebitNote.find_dn_history(params[:id]).last
    not_found if @debit_note.blank?
  end

  def get_dn_history
    add_breadcrumb "DN History", :order_to_payments_get_dn_history_path
    @past_dn = DebitNote.order("created_at desc").where("order_number=?", @debit_note.order_number).page(params[:page]).per(5)
    not_found if @past_dn.blank?
  end

  private
  def get_debit_notes
    @results = DebitNote.only_type_in.where("state!=3 OR state IS NULL").where(:is_history => false).filter_debit_notes(params).accessible_by(current_ability).order("cast(order_number AS integer) DESC")
  end

  def get_self_debit_note
    @debit_note = DebitNote.find_by_id(params[:id])
  end

  #desc: untuk mengambil count debitnote untuk smua status, agar ditampilkan di dashboard
  def get_count_revision
    @count_rev = DebitNote.where("order_number = ? AND state = ?", "#{@debit_note.order_number}", 2).count
  end


end

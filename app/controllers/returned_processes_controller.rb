class ReturnedProcessesController < ApplicationController
  layout "main"
  load_and_authorize_resource @results, @returned_process
  add_breadcrumb 'Returned Process', :returned_processes_path
  before_filter :find_retur, only: [:show,:new_dispute_retur, :create_disputed_retur, :new_receive_retur, :create_receive_retur,:new_revise_retur,:create_revised_retur,:accept_retur,:get_details_retur,
    :generate_xls_details_grtn,:generate_pdf_details_grtn, :print_detail]
  before_filter :get_details_retur, :only=>[:show]
  before_filter :find_retur_history, :only=>[:get_retur_history]

  def index
    @results = ReturnedProcess.where(:is_history => false).search(params).order("returned_processes.created_at DESC").where("returned_processes.is_completed = true").readonly(false).accessible_by(current_ability)
    if(params["format"] == "xls")
      @results_all = ReturnedProcess.where(:is_history => false).search(params).order("returned_processes.created_at DESC").where("returned_processes.is_completed = true").readonly(false).accessible_by(current_ability)
    end
    respond_to do |f|
      f.html
      f.js
      f.xls
    end
  end

  def show
    add_breadcrumb "Detail", :returned_process_path
    @retur.read if @retur.can_read?
    @details = @returned_process.returned_process_details.order("seq ASC")
  end

  def generate_xls_details_grtn
    send_file @retur.export_to_xls["path"], :disposition => 'inline', :type => 'application/xls', :filename => "GRTN-#{@retur.rp_number}.xls"
  end

  def generate_pdf_details_grtn
    @grtn_disputed = ReturnedProcess.where(:rp_number => "#{@retur.rp_number}").where("state in (4,5,6)").order("created_at ASC")
    @grtn_details = @retur.returned_process_details
    render :pdf => "GRTN-#{@retur.rp_number}",
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'returned_processes/grtn.pdf.erb',
      :page_size => 'A4',
      :lowquality => false,
      :title => "#{GRTN}"
  end

  def generate_pdf_all_rp
      title = "RP_ALL_#{Time.new.strftime('%d-%m-%Y')}"
      @results = ReturnedProcess.where(:is_history => false).search(params).order("returned_processes.created_at DESC").where("returned_processes.is_completed = true").readonly(false).accessible_by(current_ability)
      render :pdf => title,
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'returned_processes/rp_all.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def print_detail
    @grtn_disputed = ReturnedProcess.where(:rp_number => "#{@retur.rp_number}", :id => params[:id]).order("created_at ASC")
    @grtn_details = @grtn_disputed.last.returned_process_details
    render :pdf => "Detail GRTN-#{@retur.rp_number}",
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'returned_processes/print_detail.pdf.erb',
      :page_size => 'A4',
      :lowquality => false,
      :title => "#{GRTN}"
  end

  def new_receive_retur
    if @retur.can_receive?
       @retur_receive = ReturnedProcess.new
       @retur_receive.returned_process_details.build
       @details = @retur.returned_process_details.order("seq ASC")
    else
      not_authorized
    end
  end

  #desc: synch PO yang untuk type Retur
  def synch
    @results = PurchaseOrder.synch_retur_now
    status = eval_status_res(@results)
    send_email_which_service_api_is_not_connected(status)
    respond_to do |f|
      @back_to_index = "#{returned_processes_path}"
      f.js {render :layout => false, :status=>status}
    end
  end

  def create_receive_retur
    @flag = false
    if @retur.can_receive?
      #desc: membuat receive retur
      if params[:receive_retur]
        if @retur.receive_retur(params[:returned_process], current_user)
          @details = @retur.returned_process_details
          @message = "Retur was succesfully received"
          @flag = true
        else
          @message = "An error has ocurred on saving return, please check your inputs again.".html_safe
        end
      #desc: membuat save retur menjadi draft
      elsif params[:save_retur]
        @retur.insert_details_retur(params[:returned_process])
        if @retur.update_attributes(params[:returned_process])
          @details = @retur.returned_process_details
          @message = "Retur was succesfully saved"
          @flag = true
        else
          @message = "An error has ocurred on saving return, please check your inputs again.".html_safe
        end
      elsif params[:cancel]
        #desc: membuat cancel retur
        respond_to do |format|
          format.html {redirect_to returned_process_path(@retur.id)}
          format.js {
            render :js=> "window.location = '#{returned_process_path(@retur.id)}'"
          }
        end
      else
        redirect_error(@retur)
      end
    else
      not_authorized
    end
  end

  def new_dispute_retur
    if @retur.can_raise_dispute?
      @retur_dispute = ReturnedProcess.new
      @retur_dispute.returned_process_details.build
      @details=@retur.returned_process_details.order("seq ASC")
    else
      not_authorized
    end
  end

  def create_disputed_retur
    @flag = false
    if @retur.can_raise_dispute?
       #desc: save retur menjadi draft
      if params[:save_retur]
        @retur.insert_details_retur(params[:returned_process])
        if @retur.update_attributes(params[:returned_process])
          @details = @retur.returned_process_details
          @message = "Disputed retur draft was succesfully saved"
          @flag = true
        else
          @message = "An error has ocurred on saving return, please check your inputs again. ".html_safe
        end
      elsif params[:dispute_retur]
        unless params[:returned_process][:remark].blank?
          #desc: membuat disputed retur
          @retur_dispute = ReturnedProcess.create_disputed_retur(params, current_user)
          if @retur_dispute.instance_of?(ReturnedProcess) || @retur_dispute == true
            @retur_dispute.respond_to_retur(params, current_user)
            @details = @retur_dispute.returned_process_details
            @message = "Retur was disputed"
            @flag=true
          else
            @message = "An error has ocurred on saving return, please check your inputs again.".html_safe
          end
        else
          @message = "Please, fill remark when Dispute #{GRTN}"
        end
      elsif params[:cancel]
        #desc: cancel retur
        respond_to do |format|
          format.html {redirect_to returned_process_path(@retur.id)}
          format.js {
            render :js=> "window.location = '#{returned_process_path(@retur.id)}'"
          }
        end
      else
        redirect_error(@retur)
      end
    else
      not_authorized
    end
  end

  def new_revise_retur
    if @retur.can_revise?
       @retur_revise = ReturnedProcess.new
       @retur_revise.returned_process_details.build
       @details = @retur.returned_process_details.order("seq ASC")
    else
      not_authorized
    end
  end


  def create_revised_retur
    @flag =false
    if @retur.can_revise?
      if params[:save_retur]
        #desc: save retur menjadi draft
        @retur.insert_details_retur(params[:returned_process])
        if @retur.update_attributes(params[:returned_process])
          @details = @retur.returned_process_details
          @message = "Rejected retur draft was succesfully saved"
          @flag = true
        else
          @message = "An error has ocurred on saving retur, please check your inputs again.".html_safe
        end
      elsif params[:revise_retur]
        unless params[:returned_process][:remark].blank?
          #desc: membuat revised retur
          @retur_revise = ReturnedProcess.create_revised_retur(@retur, params, current_user)
          if (@retur_revise.instance_of?(ReturnedProcess) && !@retur_revise.errors.any?) || @retur_revise == true
            @details = @retur_revise.returned_process_details
            @flag=true
            @message = "Rejected retur was successfully published"
          else
            @retur = @retur_revise
            @message = "An error has ocurred on saving retur".html_safe
          end
        else
          @message = "Please, fill remark when Dispute #{GRTN}"
        end
      elsif params[:cancel]
        #desc: cancel retur
        respond_to do |format|
          format.html {redirect_to returned_process_path(@retur.id)}
          format.js {
            render :js=> "window.location = '#{returned_process_path(@retur.id)}'"
          }
        end
      else
        redirect_error(@retur)
      end
    else
      not_authorized
    end
  end

  #desc: accepted retur final approval
  def accept_retur
    if @retur.can_accept?
      @accepted_retur = ReturnedProcess.create_accepted_retur(params,current_user)
      if @accepted_retur
        flash[:notice] = "Retur is now accepted"
        respond_to do |f|
          f.html {
            redirect_to returned_processes_path
          }
          f.js {
            render :js=> "window.location = '#{returned_processes_path}'"
          }
        end
      else
        respond_to do |f|
          f.html {
            flash[:error] = "An error ocurred when accepting retur, please try again later"
            render 'show'
          }
          f.js {
            @message = "An error has ocurred on accepting retur, please try again later"
            render 'error_accept.js.erb'}
        end
      end
    else
      not_authorized
    end
  end

  #desc: meanmilkan history retur
  def get_retur_history
    add_breadcrumb "History", :get_retur_history_returned_processes_path
    @past_retur = ReturnedProcess
                      .order("updated_at desc")
                      .where("rp_number like ?", "%#{@retur.rp_number}%")
                      .page(params[:page])
                      .per(params[:row] ? params[:row] : 5)
    not_found if @past_retur.blank?
  end

  private
  def find_retur
    @retur = ReturnedProcess.find_retur(params[:id]).last
    not_found if @retur.nil?
  end

  def get_details_retur
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
      @details= @retur.returned_process_details.order("seq ASC").page(params[:page]).per(PER_PAGE)
    end
  end

  def find_retur_history
    @retur = ReturnedProcess.find_retur_history(params[:id]).last
    not_found if @retur.nil?
  end

  def redirect_error(retur)
    flash[:error] = "You just can't do that"
      respond_to do |format|
        format.html { redirect_to returned_processes_path}
        format.js {
          render :js=> "window.location = '#{returned_processes_path}'"
        }
    end
  end
end

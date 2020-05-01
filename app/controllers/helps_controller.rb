class HelpsController < ApplicationController
  def index
    #@helps = Help.find(params[:controller])
  end

  def new

  end

  def show
    @help = Help.find_by_page(params[:id])
    if @help.blank?
      @help = Help.create(:description => 'Bantuan ini baru saja dibuat otomatis, klik Edit untuk mengubahnya.', :page => params[:id])
    end
    respond_to do |format|
      #format.html
      format.js
    end
  end

  def edit
    @help = Help.find(params[:id])
    respond_to do |format|
      #format.html
      format.js
    end
  end

  def update
    @help = Help.find(params[:id])
    if @help.update_attributes(params[:help])
      respond_to do |f|
        f.js {
          #render :js => "$('#modal-show-help').html('<%= escape_javascript(render 'form_show_help', :help => @help) %>');", :status => 200
          render :js => "alert('Please Re-Open the Modal to see the changes.');"
        }
      end
    end
  end
end

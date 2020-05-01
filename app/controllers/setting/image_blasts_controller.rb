class Setting::ImageBlastsController < ApplicationController
	layout "setting"
  	#add_breadcrumb 'Setting API Configuration', :new_setting_api_setting_path
  	#load_and_authorize_resource

  	def index
  	    conditions = []
  	    params[:search].each{|param|
            conditions << "LOWER(#{param[0]}::text) LIKE '%#{param[1]}%'"
        } if params[:search].present?
  	    @results = ImageBlast.where(conditions.join(' AND ')).order(default_order('image_blasts')).accessible_by(current_ability).page params[:page]
  	end
  	
  	def new
  	    @image_blast = ImageBlast.new
  	end
  	
  	def create
  	    @image_blast = ImageBlast.new(params[:image_blast])
  	    if @image_blast.save
  	        redirect_to setting_image_blasts_path
  	    else
  	        render 'new'
  	    end
  	end
  	
  	def show
  	    @image_blast = ImageBlast.find(params[:id])
  	end
  	
  	def edit
  	    @image_blast = ImageBlast.find(params[:id])
  	end
  	
  	def update
  	    @image_blast = ImageBlast.find(params[:id])
  	    if @image_blast.update_attributes(params[:image_blast])
  	        redirect_to setting_image_blasts_path
  	    else
  	        render 'edit'
  	    end
  	end
  	
  	def destroy
  	    @image_blast = ImageBlast.find(params[:id])
  	    if @image_blast.destroy
            render :layout => false, :status => 201, :text => "The Image has been removed"
        else
            render :layout => false, :status => 401, :text => "Sorry, the Image can not be deleted "
        end
    end
end
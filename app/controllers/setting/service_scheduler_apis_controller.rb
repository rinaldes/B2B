class Setting::ServiceSchedulerApisController < ApplicationController
  layout 'setting'
  add_breadcrumb 'Service Scheduler API', :setting_companies_path

  def create
  	@service = ServiceSchedulerApi.new(params[:service_scheduler_api])
  	if @service.save
      #update crontab
      system("RAILS_ENV=production whenever --update-crontab")
      system("RAILS_ENV=production nohup rake jobs:work > /dev/null 2>&1 &")
      redirect_to setting_service_scheduler_apis_path, :notice=>"Service Scheduler Api created"
    else
      render 'new'
    end
  end

  def new
    add_breadcrumb 'Add Service Scheduler API', :new_setting_company_path
  	@service=ServiceSchedulerApi.new
  end

  def edit
    add_breadcrumb 'Edit Service Scheduler API', :edit_setting_company_path
  	@service = ServiceSchedulerApi.find(params[:id])
  end

  def update
  	@service = ServiceSchedulerApi.find(params[:id])
    if @service.update_attributes(params[:service_scheduler_api])
      #update crontab
      system("whenever --update-crontab --set environment=#{Rails.env}")
      redirect_to setting_service_scheduler_apis_path, :notice=> "Service Scheduler Api edited"
    else
      render 'edit'
    end
  end

  def index
    @service = ServiceSchedulerApi.first

  end

  def get_type_time
    if params['type_time'] == 'H'
      time = 1
      val = Hash.new
      24.times do |i|
        val[time] = time
        time = time+1
        break if(time == 24)
      end
    elsif params['type_time'] == 'M'
      time = 15
      val = Hash.new
      10.times do |i|
        val[time] = time
        time = time+5
        break if(time == 60)
      end
    end
    @time = params['time']
    @type_time = val
  end
end

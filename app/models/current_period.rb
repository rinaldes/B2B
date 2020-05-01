class CurrentPeriod < ActiveRecord::Base
  attr_accessible :gl_period, :gl_year, :dl_period, :dl_year, :cl_period, :cl_year, :active

  def self.synch_now
    @last_cp = CurrentPeriod.order("updated_at ASC").last
    unless @last_cp.blank?
      last_date_stamp = @last_cp.updated_time.strftime("%Y-%m-%d") rescue nil
      last_time_stamp = @last_cp.updated_time.strftime("%H:%M:%S") rescue nil
      field = "date=#{last_date_stamp}&time=#{last_time_stamp}"
    end

    begin
      unless field.nil?
        res = OffsetApi.get_data_transaction_from_api("currentperiod", API_LIMIT, field)
      else
        offset = OffsetApi.where(:api_type=> "Current Period").last.offset rescue 0
        unless offset.nil?
          res = OffsetApi.connect_with_offset("currentperiod", API_LIMIT, offset)
        end
      end
    rescue => e
      return 2
    end

    unless res.is_a?(Net::HTTPSuccess)
      return OffsetApi.eval_net_http(res)
    end

    result = JSON.parse(res.body)
    return -1 if result['data'].blank?
    begin
      ActiveRecord::Base.transaction do
        a = CurrentPeriod.save_cp_from_api(result)
        if a != true
           ActiveRecord::Rollback
           return false
        end
      end
      return OffsetApi.update_po_api_offset("Current Period", result['count'])
    rescue => e
      ActiveRecord::Rollback
    end

    return false
  end

  def self.save_cp_from_api(params)
    params["data"].each do |param|
      #check existed cp
      data = self.where(:gl_period => param['sys_gl_per'], :gl_year => param['sys_gl_yr'],
                        :dl_period => param['sys_dl_per'], :dl_year => param['sys_dl_yr'],
                        :cl_period => param['sys_cl_per'], :cl_year => param['sys_cl_yr']).first
      if data.present?
        data.update_attributes(:active => true)
        next
      end

      return CurrentPeriod.new(:gl_period => param['sys_gl_per'], :gl_year => param['sys_gl_yr'],
                               :dl_period => param['sys_dl_per'], :dl_year => param['sys_dl_yr'],
                               :cl_period => param['sys_cl_per'], :cl_year => param['sys_cl_yr'],
                               :active => true).save
    end
  end
end

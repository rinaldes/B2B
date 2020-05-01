class OffsetApi < ActiveRecord::Base
  attr_accessible :api_type, :offset
  attr_protected :availability_status
  validates :api_type, :uniqueness=>true
  def self.update_po_api_offset(type,count)
  	flag = false
  	api = OffsetApi.where(:api_type => type).last
    if api.blank?
      new_api = OffsetApi.new(:api_type=>type,:offset=>count)
      flag = true if new_api.save
    else
      api.offset += count
      flag = true if api.save
    end
    return flag
  end

  def self.sync_debitnotelines order_number
    #curl --header "apiKey:12345678" http://localhost:8080/b2b/api/debtransline?so_order_no=21
    require "net/http"
    require "uri"
    res = ''
    request_api = URI.encode("#{api_call('api')}debtransline?so_order_no=#{order_number}")
    puts request_api
    url = URI.parse(request_api)
    req = Net::HTTP.new(url.host, url.port)
    #if Rails.env.production?
    #  req.use_ssl = true
    #else
      req.use_ssl = USE_SSL
    #end
    http = Net::HTTP::Get.new(url.request_uri)
    http['apiKey'] = api_call('key')
    res = req.request(http)

    result = JSON.parse(res.body)
    return result
  end

  def self.update_data_status_api_to_nil(type)
  	api = OffsetApi.where(:api_type => type).last
    unless api.blank?
      api.availability_status = false
      return true if api.save
    end
  end

  def self.connect_with_offset(api_type, limit, offset)
    require "net/http"
    require "uri"
    res = ''
    return res = false if !limit.is_a?(Integer) || !offset.is_a?(Integer)
    request_api = URI.encode("#{api_call('api')}#{api_type}?limit=#{limit}&offset=#{offset}")
    puts request_api
    url = URI.parse(request_api)
    req = Net::HTTP.new(url.host, url.port)
    #if Rails.env.production?
    #  req.use_ssl = true
    #else
      req.use_ssl = USE_SSL
    #end
    http = Net::HTTP::Get.new(url.request_uri)
    http['apiKey'] = api_call('key')
    res = req.request(http)
    return res
  end

  #synch api only order transaction
  def self.connect_with_only_order_offset(api_type, limit, offset, status, type)
    require "net/http"
    require "uri"
    res = ''
    return res = false if !limit.is_a?(Integer) || !offset.is_a?(Integer)
    request_api = URI.encode("#{api_call('api')}#{api_type}?status=#{status}&type=#{type}&limit=#{limit}&offset=#{offset}")
    puts request_api
    url = URI.parse(request_api)
    req = Net::HTTP.new(url.host, url.port)
    #if Rails.env.production?
    #  req.use_ssl = true
    #else
      req.use_ssl = USE_SSL
    #end
    http = Net::HTTP::Get.new(url.request_uri)
    http['apiKey'] = api_call('key')
    res = req.request(http)
    return res
  end

  def self.push_data(api_type, val)
    require "net/http"
    require "uri"
    res = ''

    request_api = URI.encode("#{api_call('api')}#{api_type}?value=#{val}")
    url = URI.parse(request_api)
    req = Net::HTTP.new(url.host, url.port)
    req.use_ssl = USE_SSL

    http = Net::HTTP::Get.new(url.request_uri)
    http['apiKey'] = api_call('key')
    res = req.request(http)

    return res
  end

  def self.get_data_transaction_from_api(api_type, limit, field)
    require "net/http"
    require "uri"
    res = ''
    #REFERENCE API WITH CLAUSE
    #========================================================================================
    #API untuk pengambilan purchase order
    #field = ["po_date_stamp","po_time_stamp","po_order_status = '40'","po_order_type = 'P'"]

    #API untuk pengambilan GRN
    #field = ["po_date_stamp","po_time_stamp","po_order_status = '70'","po_order_type = 'P'"]

    #API untuk pengambilan GRTN
    #field = ["po_date_stamp","po_time_stamp","po_order_status = '75'","po_order_type = 'R'"]
    return res = false if !limit.is_a?(Integer)
    request_api = "#{api_call('api')}#{api_type}?#{field}&limit=#{limit}"
    encode_uri = URI.encode(request_api)
    encode_uri_plus = URI.encode(encode_uri, "+")
    puts encode_uri_plus
    url = URI.parse(encode_uri_plus)
    req = Net::HTTP.new(url.host, url.port)
    #if Rails.env.production?
    #  req.use_ssl = true
    #else
      req.use_ssl = USE_SSL
    #end
    http = Net::HTTP::Get.new(url.request_uri)
    http['apiKey'] = api_call('key')
    res = req.request(http)
    return res
  end

  def self.connect_without_offset(api_type, limit)
    require "net/http"
    require "uri"
    res = ''
    return res = false if !limit.is_a? Integer
    request_api = URI.encode("#{api_call('api')}#{api_type}?limit=#{limit}")
    url = URI.parse(request_api)
    req = Net::HTTP.new(url.host, url.port)
    #if Rails.env.production?
    #  req.use_ssl = true
    #else
      req.use_ssl = USE_SSL
    #end
    http = Net::HTTP::Get.new(url.request_uri)
    http['apiKey'] = api_call('key')
    res = req.request(http)
    return res
  end

  def self.connect_with_query_debit_note(api_type, field, trans_type, query)
    require "net/http"
    require "uri"
    res = ''

    return res = false if query.blank?
    request_api = URI.encode("#{api_call('api')}#{api_type}?#{field}=#{trans_type}&limit=#{API_LIMIT}")
    url = URI.parse(request_api)
    puts url
    req = Net::HTTP.new(url.host, url.port)
    #if Rails.env.production?
    #  req.use_ssl = true
    #else
      req.use_ssl = USE_SSL
    #end
    http = Net::HTTP::Get.new(url.request_uri)
    http['apiKey'] = api_call('key')
    res = req.request(http)
    return res
  end

  def self.connect_with_query(api_type,params,query,options=nil)
    require "net/http"
    require "uri"
    res = ''
    return res = false if query.blank?
    if options.blank?
      request_api = "#{api_call('api')}#{api_type}?#{params}=#{URI.encode(query.squish)}&limit=#{API_LIMIT}"
    else
      #only synch detail retur
      request_api = "#{api_call('api')}#{api_type}?#{params}=#{URI.encode(query.squish)}&backorder_flag=#{options}&limit=#{API_LIMIT}"
    end
    puts "GET API : #{request_api}"
    encode_uri = URI.encode(request_api)
    url = URI.parse(encode_uri)
    req = Net::HTTP.new(url.host, url.port)
    #if Rails.env.production?
    #  req.use_ssl = true
    #else
      req.use_ssl = USE_SSL
    #end
    http = Net::HTTP::Get.new(url.request_uri)
    http['apiKey'] = api_call('key')
    return req.request(http)
  end

  def self.connect_api_with_query(api_type,clause)
    require "net/http"
    require "uri"
    res = ''
    request_api = "#{api_call('api')}#{api_type}?whcls=WHERE #{clause}"
    puts "GET API : #{request_api}"
    encode_uri = URI.encode(request_api)
    url = URI.parse(encode_uri)
    req = Net::HTTP.new(url.host, url.port)
    #if Rails.env.production?
    #  req.use_ssl = true
    #else
      req.use_ssl = USE_SSL
    #end

    http = Net::HTTP::Get.new(url.request_uri)
    http['apiKey'] = api_call('key')
    return req.request(http)

  end

  def self.eval_net_http(res)
    if res.is_a?(Net::HTTPUnauthorized)
       status = -3
    elsif res.is_a?(Net::HTTPServiceUnavailable)
       status = 2
    elsif res.is_a?(Net::HTTPNoContent)
      status = -1
    elsif res.is_a?(Net::HTTPPartialContent)
      status = -2
    elsif res.is_a?(Net::HTTPNotFound)
        status = -4
    elsif res.is_a?(Net::HTTPRequestTimeOut)
       status = -5
    else
      if ActiveSupport::JSON.decode(res.body)["error"].present?
        status = -6
      else
        status = 1
      end
    end
    return status
  end

  def self.connect_with_offset_systbl(api_type,limit,offset,type)
    require "net/http"
    require "uri"
    res = ''
    return res = false if !limit.is_a?(Integer) || !offset.is_a?(Integer)
    request_api = URI.encode("#{api_call('api')}#{api_type}?whcls=WHERE sys_tbl_type = '#{type}'&limit=#{limit}&offset=#{offset}&type=#{type}")
    puts request_api
    url = URI.parse(request_api)
    req = Net::HTTP.new(url.host, url.port)
    #if Rails.env.production?
    #  req.use_ssl = true
    #else
      req.use_ssl = USE_SSL
    #end
    http = Net::HTTP::Get.new(url.request_uri)
    http['apiKey'] = api_call('key')
    res = req.request(http)
    return res
  end

  def self.connect_without_offset_systbl(api_type, code, type)
    require "net/http"
    require "uri"
    res = ''
    request_api = URI.encode("#{api_call('api')}#{api_type}?filter=sys_tbl_type=#{type}&sys_tbl_code=#{code}&type=#{type}&code=#{code}")
    puts request_api
    url = URI.parse(request_api)
    req = Net::HTTP.new(url.host, url.port)
    #if Rails.env.production?
    #  req.use_ssl = true
    #else
      req.use_ssl = USE_SSL
    #end
    http = Net::HTTP::Get.new(url.request_uri)
    http['apiKey'] = api_call('key')
    res = req.request(http)
    return res
  end

  def self.connect_with_offset_debit_note(api_type, filter, offset, limit)
    require "net/http"
    require "uri"
    res = ''
    return res = false if !limit.is_a?(Integer) || !offset.is_a?(Integer)
    request_api = URI.encode("#{api_call('api')}#{api_type}?limit=#{limit}&offset=#{offset}")
    puts request_api
    url = URI.parse(request_api)
    req = Net::HTTP.new(url.host, url.port)
    #if Rails.env.production?
    #  req.use_ssl = true
    #else
      req.use_ssl = USE_SSL
    #end
    http = Net::HTTP::Get.new(url.request_uri)
    http['apiKey'] = api_call('key')
    res = req.request(http)
    return res
  end

  def self.change_avalaible_status(api_type, boolean)
    update_offset = OffsetApi.where(:api_type=>"#{api_type}").first
    unless update_offset.blank?
      update_offset.availability_status = boolean
      return update_offset.save
    end
  end

  def self.write_to_crontab_log(type,object)
    `[ -f log/crontab.log ] || touch log/crontab.log`
    case type
    when 502,501,503,504
      message = "[ERROR] Error ocurred when trying to get #{object.upcase} from api at #{Time.now.strftime('%d/%m/%Y, %H:%M')}"
    when 500
      message = "[ERROR] Internal error has ocurred when saving #{object.upcase} from api at #{Time.now.strftime('%d/%m/%Y, %H:%M')}"
    when 204
      message = "[EMPTY RESPONSE] Response was empty  from #{object.upcase} api at #{Time.now.strftime('%d/%m/%Y, %H:%M')}"
    end
    File.open(Rails.root.join("log","crontab.log"), 'a') do |file|
      file.puts message
    end
  end

  def self.write_to_email_log(type,object)
    `[ -f log/email.log ] || touch log/email.log`
    case type
    when 522
      message = "[TIME OUT] Connection was time out from #{object.upcase} at #{Time.now.strftime('%d/%m/%Y, %H:%M')}"
    when 204
      message = "[EMPTY RESPONSE] Response was empty  from #{object.upcase} at #{Time.now.strftime('%d/%m/%Y, %H:%M')}"
    end
    #diubah ku si ado karena triger brakeman to raise security concerns
    File.open(Rails.root.join("log","email.log"), 'a') do |file|
      file.puts message
    end
  end

  def self.get_offset(type)
    offset = 0
    api = OffsetApi.where(:api_type=>type).last
    if !api.blank?
      offset = api.offset
      offset = 0 if offset.nil?
      return offset
    else
      return offset
    end
  end

  def self.get_push_invoice(entity, values)
    require "net/http"
    require "uri"
    res = ''
    request_api = URI.encode("#{api_call('api')}#{entity}")
    url = URI.parse(request_api)
    p request_api
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = USE_SSL
    req = Net::HTTP::Post.new(url.request_uri, initheader = {
      'Content-Type' => 'application/json',
      'apiKey' => api_call('key')
    })
    req.body = values

    res = http.request(req)
    return res
  end

  def self.api_call(type)
    return ApiSetting.finds(type)
  end
end

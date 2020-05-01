module Connect_api

  def connect_with_offset(api_type,limit,offset)
    require "net/http"
  	require "uri"
  	res = ''
    return res = false if !limit.is_a? Integer || !offset.is_a? Integer
  	request_api = "#{ApiSetting.first.api}#{api_type}?limit=#{limit}&offset=#{offset}"
  	url = URI.parse(request_api)
  	req = Net::HTTP.new(url.host, url.port)
  	#if Rails.env.production?
    #		req.use_ssl = true
  	#else
  		req.use_ssl = USE_SSL
  	#end
  	http = Net::HTTP::Get.new(url.request_uri)
  	http['apiKey'] = ApiSetting.first.password
  	res = req.request(http)
  	return res
  end
  def connect_without_offset(api_type,limit)
  	require "net/http"
  	require "uri"
  	res = ''
    return res = false if !limit.is_a? Integer
  	request_api = "#{ApiSetting.first.api}#{api_type}?limit=#{limit}"
  	url = URI.parse(request_api)
  	req = Net::HTTP.new(url.host, url.port)
  	#if Rails.env.production?
  	#	req.use_ssl = true
  	#else
  		req.use_ssl = USE_SSL
  	#end
  	http = Net::HTTP::Get.new(url.request_uri)
  	http['apiKey'] = ApiSetting.first.password
  	res = req.request(http)
  	return res
  end
  def connect_with_query(api_type,params,query)
  	require "net/http"
  	require "uri"
  	res = ''
    return res = false if query.blank?
  	request_api = "#{ApiSetting.first.api}#{api_type}?#{params}=#{query}&limit=0"
  	url = URI.parse(request_api)
  	req = Net::HTTP.new(url.host, url.port)
  	#if Rails.env.production?
  	#	req.use_ssl = true
  	#else
  		req.use_ssl = USE_SSL
  	#end
  	http = Net::HTTP::Get.new(url.request_uri)
  	http['apiKey'] = ApiSetting.first.password
  	res = req.request(http)
  	return res
  end
  module_function :connect_with_offset,:connect_with_query,:connect_without_offset

end


module Api
  module V1
    class CustomersController < ApplicationController
      require "net/http"
      require "uri"
      skip_before_filter :authenticate_user!
      #sementara di deklarasikan sini dulu
      def callback_customers
        request_api = "#{api_call('api')}/suppliers"
        url = URI.parse(request_api)
        req = Net::HTTP.new(url.host, url.port)
        req.use_ssl = USE_SSL
        http = Net::HTTP::Get.new(url.request_uri)
        http['apiKey'] = api_call('key')
        res = req.request(http)
        result = JSON.parse(res.body)
        if Customer.save_customer_from_api(result)
          render :nothing => true, :layout => false, :status => 201
        else
          render :nothing => true, :layout => false, :status => 401
        end
      end

      def self.api_call(type)
        return ApiSetting.finds(type)
      end

    end
  end
end


module Api
  module V1
    class ProductsSuppliersController < ApplicationController
      require "net/http"
      require "uri"
      skip_before_filter :authenticate_user!
      #sementara di deklarasikan sini dulu

      def self.api_call(type)
        return ApiSetting.finds(type)
      end
    end
  end
end


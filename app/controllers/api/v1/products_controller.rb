module Api
  module V1
    class ProductsController < ApplicationController
      skip_before_filter :authenticate_user!
      #sementara di deklarasikan sini dulu
      def callback_products
        if Product.callback_products
          render :nothing => true, :layout => false, :status => 201
        else
         render :nothing => true, :layout => false, :status => 401
        end

      end
    end
  end
end


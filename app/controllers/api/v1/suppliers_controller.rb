module Api
  module V1
    class SuppliersController < ApplicationController
      def callback_suppliers
        if Supplier.callback_suppliers
          render :nothing => true, :layout => false, :status => 201
        else
          render :nothing => true, :layout => false, :status => 401
        end
      end
    end
  end
end


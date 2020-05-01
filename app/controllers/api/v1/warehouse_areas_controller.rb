module Api
  module V1
    class WarehouseAreasController < ApplicationController
      def callback_warehouse_area
        #API untuk save warehouse beserta area karena masih dalam 1 entity.
        if Warehouse.callback_warehouse_areas
          render :nothing => true, :layout => false, :status => 201
        else
          render :nothing => true, :layout => false, :status => 401
        end
      end
    end
  end
end
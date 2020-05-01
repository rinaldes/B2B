module Api
  module V1
    class PurchaseOrdersController < ApplicationController
      require "net/http"
      require "uri"
      skip_before_filter :authenticate_user!
      #sementara di deklarasikan sini dulu
      def po_forever
        offset = OffsetApi.where(:api_type => "Purchase Order").first
        unless offset.blank?
          while offset.availability_status
            result = PurchaseOrder.synch_po_now
            if result != true
              if result == -2
                offset.availability_status = false
                render :nothing => true, :layout => false, :status => 204
              end
            end
          end
        end
        offset.save
        render :nothing => true, :layout => false, :status => 200
      end
    end
  end
end


#this seed is used for generate feature for all method on controllers
#if you say "all of them?? are you nuts? that will take a month?", I would say, hell yeah
after :suppliers, :users do
 if Rails.env.development? || Rails.env.staging? || Rails.env.production? || Rails.env.vmware?
   feature = Feature.first
   if feature.blank?
      controllers = Rails.application.routes.routes.map do |route|
        {
          controller: route.defaults[:controller], action: route.defaults[:action]
        }
      end.uniq.compact
      exception = ["","devise", "rails", "api", "application"]
      controllers.each do |cont|
        unless cont[:controller].blank? && cont[:action].blank?
          if cont[:controller].include?("/")
            raw = cont[:controller].split("/")
            next if exception.include?("#{raw[0]}")
            controller = raw.last
          else
            controller = cont[:controller]
          end
          except_method = []
          case "#{controller}".downcase
            when "dashboards"
              except_method = ["get_tab_for", "get_po_stats","count_disputed_po", "get_all_po_status_statistic", "disputed_dn","get_dn_stats", "count_disputed_dn", "get_report", "detail_report_orders","detail_report_return", "detail_report_debit_note"]
            when "suppliers"
              except_method = ["show", "update_level", "update_service_level","update_barcode_setting"]
            when "suppliers_groups"
              except_method = ["show"]
            when "warehouses"
              except_method = ["show", "update_email_notification", "update_level_limit", "update_area"]
            when "warehouses_groups"
              except_method = ["show"]
            when "products"
              except_method = ["show"]
            when "payments"
              except_method = ["search_pv", "search_dn","show", "new"]
            when "payment_vouchers"
              except_method = ["get_invoice_based_on_supplier","show", "new",]
            when "purchase_orders"
              except_method = ["show"]
            when "advance_shipment_notifications"
              except_method = ["show", "new_asn"]
            when "goods_receive_notes"
              except_method = ["show","new_dispute_grn", "new_revise_dispute_grn"]
            when "goods_receive_price_confirmations"
              except_method = ["show","new_dispute_grpc","new_revise_dispute_grpc"]
            when "invoices"
              except_method = ["print","show"]
            when "returned_processes"
              except_method = ["show","new_receive_retur", "new_dispute_retur", "new_revise_retur"]
            when "debit_notes"
              except_method = ["get_take_action", "show","synch_new_payment_debit_note","print"]
            when "companies"
              except_method = ["update", "new", "create"]
            when "type_of_users"
              except_method = ["get_this_company", "update", "check_is_supplier", "get_supplier"]
            when "users"
              except_method = ["new", "select_warehouses", "select_suppliers", "update_change_email_notif", "update_password", "update", "show", "select_supplier_or_warehouse", "get_supplier", "update_features"]
            when "roles"
              except_method = ["new", "update", "show","update_features"]
            when "service_levels"
              except_method = ["new", "show","update"]
            when "ldap_settings"
              except_method = ["new"]
            when "notifications"
              except_method = ["new", "update", "show", "short_notif", "show_notif", "change_notif_state"]
            when "email_notifications"
              except_method = []
            when "early_payment_requests"
              except_method = ["show_detail_bank", "new_detail_bank", "create_detail_bank"]
            when "user_logs"
              except_method = []
            when "reports"
              except_method = ["index","new","create","show","edit","update","destroy"]
            when "api_settings"
              except_method = ["new"]
            else
              next
          end

          next if except_method.include?("#{cont[:action]}")
          feature = Feature.save_a_new_feature(cont)
          if feature
            puts "Feature with name #{feature.name} and regulator #{feature.regulator} has been saved"
            flag = false
            case feature.name
              when "Report purchase order"
                flag = true
              when "Report goods receive notes"
                flag = true
              when "Report goods receive price confirmations"
                flag = true
              when "Report goods return note"
                flag = true
              else
                if controller.downcase == "dashboards" && (cont[:action] != "report_invoice" && cont[:action] != "report_debit_note")
                  flag = true
                end
                if controller.downcase == "users" || controller.downcase == "suppliers" || controller.downcase == "warehouses" || controller.downcase == "products"
                  flag = true
                end
            end
            if flag
              User.all.each do |u|
                unless u.has_role?("superadmin")
                  if u.has_role? :supplier_admin_group
                    next if feature.regulator == "Warehouse"
                  elsif u.has_role? :customer_admin_group
                    next if feature.regulator == "Supplier"
                  end
                  u.features << feature
                end
              end
            end
          else
            puts "An error has ocurred when saving feature"
          end
        end
      end
   end
 end
end

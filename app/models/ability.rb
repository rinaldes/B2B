class Ability
  include CanCan::Ability

  def initialize(user)
    alias_action :update, :edit, to: :modify
    alias_action :new, :create, to: :make
    alias_action :index, :show, to: :read
    alias_action :new, :create, :update, :edit, :new, :edit, :destroy, :show, to: :crud
    alias_action :change_password, :update_password, to: :edit_password
    alias_action :new_asn, :create_asn, to: :make_asn
    alias_action :new_dispute_grn, :create_dispute_grn, to: :make_dispute_grn
    alias_action :new_revise_dispute_grn, :create_revise_dispute_grn, to: :make_revise_dispute_grn
    alias_action :new_dispute_grpc, :create_dispute_grpc, to: :make_dispute_grpc
    alias_action :new_revise_dispute_grpc, :create_revise_disputed_grpc, to: :make_revise_dispute_grpc
    alias_action :get_grn_history, to: :read_grn_history
    alias_action :get_grpc_history, to: :read_grpc_history
    alias_action :print_inv, :print, to: :print_invoice
    alias_action :new_receive_retur, :create_receive_retur, to: :receive_retur
    alias_action :new_dispute_retur, :create_disputed_retur, to: :make_dispute_retur
    alias_action :new_revise_retur, :create_revised_retur, to: :make_revise_retur
    alias_action :get_retur_history, to: :read_retur_history
    alias_action :edit_level, :update_level, to: :change_level
    alias_action :edit_barcode_setting, :update_barcode_setting, to: :change_barcode_setting
    alias_action :edit_service_level, :update_service_level, to: :change_service_level
    alias_action :edit_level_limit, :update_level_limit, to: :change_level_limit
    alias_action :edit_email_notification, :update_email_notification, to: :change_email_notification
    alias_action :set_area, :update_area, to: :change_area

    if user.has_role? :superadmin
      can :manage, :all
    else
      # supplier group level settings
      supplier = user.supplier
      if supplier.present?
        group = supplier.group
        if group.present?
          details = group.supplier_level_details.pluck(:text)
          if details.length > 0
            can :view, :report
          end

          details.each do |suplvl|
            case suplvl
            when "Service Level Supplier"
              can :service_level_suppliers, :report
            when "On Going Disputes"
              can :on_going_disputes, :report
            when "Pending Deliveries"
              can :pending_deliveries, :report
            when "Return Histories"
              can :returned_histories, :report
            when "Account Payable"
              can :account_payable, :report
            when "Account Receivable"
              can :account_receivable, :report
            when "Payment Progress"
              can :payment_progress, :report
            end
          end
        end
      end
      if user.warehouse.present?
        can :view, :report
        can :service_level_suppliers, :report
        can :on_going_disputes, :report
        can :pending_deliveries, :report
        can :returned_histories, :report
        can :account_payable, :report
        can :account_receivable, :report
        can :payment_progress, :report
      end

      # other settings
      warehouse = ''
      supplier = ''
      group = ''
      group_flag = false
      unless user.warehouse.blank?
        warehouse = user.warehouse
        group = warehouse.group unless warehouse.group.blank?
      end
      unless user.supplier.blank?
        supplier = user.supplier
        group = supplier.group unless supplier.group.blank?
      end
      group_flag = user.roles.first.group_flag unless group.blank?

      user.roles.first.features.each do |feature|
        feature.key = feature.key.split('/')[1]
        # diubah ku aing pake case berdasarkan feature.regulator
        case feature.regulator
        when 'Dashboard'
          case feature.key
          when 'index'
            can [:index, :get_selected_state_stats], :dashboard
            can [:get_all_po_status_statistic, :get_po_stats], :dashboard
            can :report_purchase_order, :dashboard if feature.name == 'Report purchase Order'
            can :report_goods_receive_notes, :dashboard if feature.name == 'Report goods receive notes'
            can :report_goods_receive_price_confirmations, :dashboard if feature.name == 'Report goods receive price confirmations'
            can :report_invoice, :dashboard if feature.name == 'Report invoice'
            can :report_goods_return_note, :dashboard if feature.name == 'Report goods return note'
            can :report_debit_note, :dashboard if feature.name == 'Report debit note'
            can :get_report, :dashboard
            can :detail_report_orders, :dashboard
            can :detail_report_return, :dashboard
            can :detail_report_debit_note, :dashboard
            can :get_suppliers, :dashboard
            can :get_service_level_flot_by_supplier, :dashboard
          when 'count_po_today_statuses'
            can [:count_po_today_statuses, :get_tab_for, :count_disputed_po, :count_grtn_today_statuses], :dashboard
          when 'for_sl_statistic'
            can [:for_sl_statistic], :dashboard
            can :read, ServiceLevelHistory, supplier_id: supplier.id unless supplier.blank?
            can :read, ServiceLevelHistory, supplier: { group_id: group.id } if group_flag && !supplier.blank?
            can :read, ServiceLevelHistory unless warehouse.blank?
          when 'get_all_po_status_statistic'
            can [:get_all_po_status_statistic, :get_po_stats, :get_dn_stats], :dashboard
          else
            can feature.key.to_sym, :dashboard
          end
        when 'Supplier'
          # define ability for suppliers controller
          case feature.key
          when 'index', 'show'
            can :read, Supplier, id: supplier.id unless supplier.blank?
            can :read, Supplier, group: { id: group.id } if group_flag && !group.blank?
            can :read, Supplier unless warehouse.blank?
            can :read, :supplier
            can :read, Supplier unless warehouse.blank?
            can :read, :suppliers_group
            can :read, Group, group_type: 'Supplier', id: group.id unless group.blank?
            can :read, Group, group_type: 'Supplier' unless warehouse.blank?
          when 'edit_level', 'update_level'
            can :change_level, :suppliers_group
            # can :change_level, :supplier
            can :change_level, Supplier unless warehouse.blank?
            can :change_level, Supplier, id: supplier.id unless supplier.blank?
            can :change_level, Supplier, group: { id: group.id } if group_flag && !supplier.blank?
          when 'edit_barcode_setting', 'update_barcode_setting'
            can :change_barcode_setting, :supplier
            can :change_barcode_setting, Supplier, group: { id: group.id } if group_flag && !supplier.blank?
            can :change_barcode_setting, Supplier, id: supplier.id unless supplier.blank?
            can :change_barcode_setting, Supplier  unless warehouse.blank?
            can :manage, BarcodeSettingsSupplier, supplier_id: supplier.id unless supplier.blank?
            can :manage, BarcodeSettingsSupplier, supplier: { group_id: group.id } if group_flag && !supplier.blank?
            can :manage, BarcodeSettingsSupplier unless warehouse.blank?
          when 'edit_service_level', 'update_service_level'
            can :change_service_level, :supplier
            can :read, ServiceLevel
            can :change_service_level, Supplier unless warehouse.blank?
            can :change_service_level, Supplier, id: supplier.id unless supplier.blank?
            can :change_service_level, Supplier, group: { id: group.id } if group_flag && !supplier.blank?
          when 'synch_suppliers_now'
            can :synch_suppliers_now, Supplier
          when 'synch_supplier_based_on_accountcode'
            can :synch_supplier_based_on_accountcode, Supplier
          else
            can feature.key.to_sym, :supplier
          end
        when 'SuppliersGroup'
          case feature.key
          when 'index', 'show'
            can :read, :suppliers_group
            can :read, Group, group_type: 'Supplier', id: group.id unless group.blank?
            can :read, Group, group_type: 'Supplier' unless warehouse.blank? || supplier.present?
          when 'edit_level', 'update_level'
            can :change_level, :suppliers_group
            can :change_level, Group unless group.blank?
            can :change_level, Group, id: supplier.group_id unless supplier.blank?
            can :change_level, Group, group: { id: group.id } if group_flag && !supplier.blank?
          else
            can feature.key.to_sym, :suppliers_group
          end
        when 'Warehouse'
          case feature.key
          when 'index', 'show'
            can :read, :warehouse
            can :read, Warehouse, id: warehouse.id unless warehouse.blank?
            can :read, Warehouse, group: { id: group.id } if group_flag && !group.blank?
            can :read, :warehouses_group
            can :read, Group, group_type: 'Warehouse', id: group.id unless group.blank? || warehouse.blank?

            # can :read, :warehouse
            # unless warehouse.blank?
            #  can :read, Warehouse, :id => warehouse.id unless warehouse.blank?
            #  can :read, Warehouse, :group => {:id => group.id} if group_flag && !warehouse.blank?
            # else
            #  can :read, Warehouse
            # end
          when 'edit_level_limit', 'update_level_limit'
            can :change_level_limit, :warehouse
            can :change_level_limit, Warehouse, id: warehouse.id unless warehouse.blank?
          when 'synch_warehouse_based_on_code'
            can :synch_warehouse_based_on_code, :warehouse
            can :synch_warehouse_based_on_code, Warehouse, id: warehouse.id unless warehouse.blank?
            can :synch_warehouse_based_on_code, Warehouse, group: { id: group.id } if group_flag && !warehouse.blank?
          when 'edit_email_notification', 'update_email_notification'
            can :change_email_notification, :warehouse
            can :change_email_notification, Warehouse, id: warehouse.id unless warehouse.blank?
            can :change_email_notification, Warehouse, group: { id: group.id } if group_flag && !warehouse.blank?
          when  'set_area', 'update_area'
            can :change_area, :warehouse
            can :change_area, Warehouse, id: warehouse.id unless warehouse.blank?
            can :change_area, Warehouse, group: { id: group.id } if group_flag && !warehouse.blank?
          when 'synch_warehouses_now'
            can :synch_warehouses_now, :warehouse
            can :synch_warehouses_now, Warehouse, id: warehouse.id unless warehouse.blank?
            can :synch_warehouses_now, Warehouse, group: { id: group.id } if group_flag && !warehouse.blank?
          else
            can feature.key.to_sym, :warehouse
          end
        when 'WarehousesGroup'
          case feature.key
          when 'index', 'show'
            can :read, :warehouses_group
            can :read, Group, group_type: 'Warehouse', id: group.id unless group.blank?
            can :read, Group, group_type: 'Warehouse' unless warehouse.blank?
          when 'edit_level', 'update_level'
            can :change_level, :suppliers_group
            can :change_level, Group unless group.blank?
            can :change_level, Group, id: supplier.group_id unless supplier.blank?
            can :change_level, Group, group: { id: group.id } if group_flag && !supplier.blank?
          else
            can feature.key.to_sym, :suppliers_group
          end
        when 'Product'
          case feature.key
          when 'show', 'index'
            if supplier.present?
              can :read, Product, suppliers: { id: supplier.id }
            elsif warehouse.present?
              can :read, Product
            elsif group_flag.present?
              if supplier.present? || warehouse.present?
                can :read, Product, suppliers: { group: { id: group.id } }
              end
            end

          when 'synch_products_now'
            can :synch_products_now, :product
            can :synch_products_now, Product
          when 'synch_product_based_on_code'
            can :synch_product_based_on_code, Product unless warehouse.blank?
            can :synch_product_based_on_code, Product, suppliers: { id: supplier.id } unless supplier.blank?
            can :synch_product_based_on_code, Product, suppliers: { group: { id: group.id } } if group_flag && !supplier.blank?
          else
            can feature.key.to_sym, :product
          end
        when 'PurchaseOrder'
          case feature.key
          when 'index', 'show'
            can :read, :purchase_order
            can :read, PurchaseOrder, supplier_id: supplier.id, order_type: PO.to_s unless supplier.blank?
            can :read, PurchaseOrder, warehouse_id: warehouse.id, order_type: PO.to_s unless warehouse.blank?
            can :read, PurchaseOrder, warehouse: { group_id: group.id } if group_flag && !warehouse.blank?
            can :read, PurchaseOrder, supplier: { group: { id: group.id } } if group_flag && !supplier.blank?
          when 'synch_po_now'
            can :synch_po_now, :purchase_order
            can :synch_po_now, PurchaseOrder
          else
            can feature.key.to_sym, :purchase_order
          end
        when 'AdvanceShipmentNotification'
          case feature.key
          when 'index', 'show'
            can :read, :advance_shipment_notification
            can :read, PurchaseOrder, supplier_id: supplier.id, order_type: ASN.to_s unless supplier.blank?
            can :read, PurchaseOrder, warehouse_id: warehouse.id, order_type: ASN.to_s unless warehouse.blank?
            can :read, PurchaseOrder, warehouse: { group: { id: group.id } }, order_type: ASN.to_s if group_flag && !warehouse.blank?
            can :read, PurchaseOrder, supplier: { group: { id: group.id } }, order_type: ASN.to_s if group_flag && !supplier.blank?
          when 'new_asn', 'create_asn'
            can :make_asn, :advance_shipment_notification
            can [:make_asn, :make], PurchaseOrder, supplier_id: supplier.id unless supplier.blank?
            can [:make_asn, :make], PurchaseOrder, supplier: { group: { id: group.id } } if group_flag && !supplier.blank?
            can [:make_asn, :make], PurchaseOrder, warehouse: { group: { id: group.id } } if group_flag && !warehouse.blank?
            can :make_asn, PurchaseOrder, warehouse_id: warehouse.id unless warehouse.blank?
          else
            can feature.key.to_sym, :advance_shipment_notification
            can feature.key.to_sym, PurchaseOrder, order_type: ASN.to_s
          end
        when 'GoodsReceiveNote'
          case feature.key
          when 'index', 'show'
            can :read, :goods_receive_note
            can :read, PurchaseOrder, supplier_id: supplier.id, order_type: GRN.to_s unless supplier.blank?
            can :read, PurchaseOrder, warehouse_id: warehouse.id, order_type: GRN.to_s unless warehouse.blank?
            can :read, PurchaseOrder, warehouse: { group: { id: group.id } }, order_type: GRN.to_s if group_flag && !warehouse.blank?
            can :read, PurchaseOrder, supplier: { group: { id: group.id } }, order_type: GRN.to_s if group_flag && !supplier.blank?
            can :show_grn_serial, PurchaseOrder
          when  'new_dispute_grn', 'create_dispute_grn'
            can :make_dispute_grn, :goods_receive_note
            can :make_dispute_grn, PurchaseOrder, order_type: GRN.to_s, supplier_id: supplier.id unless supplier.blank?
            can :make_dispute_grn, PurchaseOrder, order_type: GRN.to_s, supplier: { group_id: group.id } if group_flag && !supplier.blank?
            can :make_dispute_grn, PurchaseOrder, order_type: GRN.to_s, warehouse_id: warehouse.id unless warehouse.blank?
            can :make_dispute_grn, PurchaseOrder, order_type: GRN.to_s, warehouse: { group: { id: group.id } } if group_flag && !warehouse.blank?
          when 'new_revise_dispute_grn', 'create_revise_dispute_grn'
            can :make_revise_dispute_grn, :goods_receive_note
            can :make_revise_dispute_grn, PurchaseOrder, order_type: GRN.to_s, supplier_id: supplier.id unless supplier.blank?
            can :make_revise_dispute_grn, PurchaseOrder, order_type: GRN.to_s, supplier: { group: { id: group.id } } if group_flag && !supplier.blank?
            can :make_revise_dispute_grn, PurchaseOrder, order_type: GRN.to_s, warehouse_id: warehouse.id unless warehouse.blank?
            can :make_revise_dispute_grn, PurchaseOrder, order_type: GRN.to_s, warehouse: { group: { id: group.id } } if group_flag && !warehouse.blank?
          when 'accept_grn'
            can :accept_grn, :goods_receive_note
            can :accept_grn, PurchaseOrder, order_type: GRN.to_s, supplier_id: supplier.id unless supplier.blank?
            can :accept_grn, PurchaseOrder, order_type: GRN.to_s, supplier: { group: { id: group.id } } if group_flag && !supplier.blank?
            can :accept_grn, PurchaseOrder, order_type: GRN.to_s, warehouse_id: warehouse.id unless warehouse.blank?
            can :accept_grn, PurchaseOrder, order_type: GRN.to_s, warehouse: { group: { id: group.id } } if group_flag && !warehouse.blank?
          when 'get_grn_history'
            can :read_grn_history, :goods_receive_note
            can :read_grn_history, PurchaseOrder, order_type: GRN.to_s
          when 'synch_grn_now'
            can :synch_grn_now, :goods_receive_note
            can :synch_grn_now, PurchaseOrder
          else
            can feature.key.to_sym, :goods_receive_note
            can feature.key.to_sym, PurchaseOrder, order_type: GRN.to_s
          end
        when 'GoodsReceivePriceConfirmation'
          case feature.key
          when 'index', 'show'
            can :read, :goods_receive_price_confirmation
            can :read, PurchaseOrder, supplier_id: supplier.id, order_type: GRPC.to_s unless supplier.blank?
            can :read, PurchaseOrder, warehouse_id: warehouse.id, order_type: GRPC.to_s unless warehouse.blank?
            can :read, PurchaseOrder, warehouse: { group: { id: group.id } }, order_type: GRPC.to_s if group_flag && !warehouse.blank?
            can :read, PurchaseOrder, supplier: { group: { id: group.id } }, order_type: GRPC.to_s if group_flag && !supplier.blank?
          when 'new_dispute_grpc', 'create_dispute_grpc'
            can :make_dispute_grpc, :goods_receive_price_confirmation
            can :make_dispute_grpc, PurchaseOrder, order_type: GRPC.to_s, supplier_id: supplier.id unless supplier.blank?
            can :make_dispute_grpc, PurchaseOrder, order_type: GRPC.to_s, supplier: { group: { id: group.id } } if group_flag && !supplier.blank?
            can :make_dispute_grpc, PurchaseOrder, order_type: GRPC.to_s, warehouse_id: warehouse.id unless warehouse.blank?
            can :make_dispute_grpc, PurchaseOrder, order_type: GRPC.to_s, warehouse: { group: { id: group.id } } if group_flag && !warehouse.blank?
          when 'new_revise_dispute_grpc', 'create_revise_disputed_grpc'
            can :make_revise_dispute_grpc, :goods_receive_price_confirmation
            can :make_revise_dispute_grpc, PurchaseOrder, order_type: GRPC.to_s, warehouse_id: warehouse.id unless warehouse.blank?
            can :make_revise_dispute_grpc, PurchaseOrder, order_type: GRPC.to_s, warehouse: { group_id: group.id } if group_flag && !warehouse.blank?
            can :make_revise_dispute_grpc, PurchaseOrder, order_type: GRPC.to_s, supplier_id: supplier.id unless supplier.blank?
            can :make_revise_dispute_grpc, PurchaseOrder, order_type: GRPC.to_s, supplier: { group_id: group.id } if group_flag && !supplier.blank?
          when 'accept_grpc'
            can :accept_grpc, :goods_receive_price_confirmation
            can :accept_grpc, PurchaseOrder, order_type: GRPC.to_s, supplier_id: supplier.id unless supplier.blank?
            can :accept_grpc, PurchaseOrder, order_type: GRPC.to_s, supplier: { group: { id: group.id } } if group_flag && !supplier.blank?
            can :accept_grpc, PurchaseOrder, order_type: GRPC.to_s, warehouse_id: warehouse.id unless warehouse.blank?
            can :accept_grpc, PurchaseOrder, order_type: GRPC.to_s, warehouse: { group: { id: group.id } } if group_flag && !warehouse.blank?
          when 'get_grpc_history'
            can :read, :goods_receive_price_confirmation
            can :read_grpc_history, PurchaseOrder, order_type: GRPC.to_s
          else
            can feature.key.to_sym, :goods_receive_price_confirmation
            can feature.key.to_sym, PurchaseOrder, order_type: GRPC.to_s
          end
        when 'Invoice'
          case feature.key
          when 'index', 'show'
            can :read, :invoice
            can :read, PurchaseOrder, supplier_id: supplier.id, order_type: INV.to_s unless supplier.blank?
            can :read, PurchaseOrder, supplier: { group_id: group.id }, order_type: INV.to_s if group_flag && !supplier.blank?
            can :read, PurchaseOrder, warehouse_id: warehouse.id, order_type: INV.to_s unless warehouse.blank?
            can :read, PurchaseOrder, warehouse: { group_id: group.id }, order_type: INV.to_s if group_flag && !warehouse.blank?
          when 'print_inv'
            can [:print_inv, :print], :invoice
            can [:print_inv, :print], PurchaseOrder, order_type: INV.to_s, supplier_id: supplier.id unless supplier.blank?
            can [:print_inv, :print], PurchaseOrder, order_type: INV.to_s, supplier: { group_id: group.id } if group_flag && !supplier.blank?
            can [:print_inv, :print], PurchaseOrder, order_type: INV.to_s, warehouse_id: warehouse.id unless warehouse.blank?
            can [:print_inv, :print], PurchaseOrder, order_type: INV.to_s, warehouse: { group_id: group.id } if group_flag && !warehouse.blank?
          when 'send_invoice_payment_request'
            can :send_invoice_payment_request, :invoice
            can :send_invoice_payment_request, PurchaseOrder, order_type: INV.to_s, supplier_id: supplier.id unless supplier.blank?
            can :send_invoice_payment_request, PurchaseOrder, order_type: INV.to_s, supplier: { group_id: group.id } if group_flag && !supplier.blank?
            can :send_invoice_payment_request, PurchaseOrder, order_type: INV.to_s, warehouse_id: warehouse.id unless warehouse.blank?
            can :send_invoice_payment_request, PurchaseOrder, order_type: INV.to_s, warehouse: { group_id: group.id } if group_flag && !warehouse.blank?
          when 'respond_to_inv'
            can :respond_to_inv, :invoice
            can :respond_to_inv, PurchaseOrder, order_type: INV.to_s, supplier_id: supplier.id unless supplier.blank?
            can :respond_to_inv, PurchaseOrder, order_type: INV.to_s, supplier: { group_id: group.id } if group_flag && !supplier.blank?
            can :respond_to_inv, PurchaseOrder, order_type: INV.to_s, warehouse_id: warehouse.id unless warehouse.blank?
            can :respond_to_inv, PurchaseOrder, order_type: INV.to_s, warehouse: { group_id: group.id } if group_flag && !warehouse.blank?
          else
            can feature.key.to_sym, :invoice
            can feature.key.to_sym, PurchaseOrder, order_type: INV.to_s
          end
        when 'DebitNote'
          case feature.key
          when 'index', 'show'
            can :read, :debit_note
            can :read, DebitNote, supplier_id: supplier.id unless supplier.blank?
            can :read, DebitNote, supplier: { group_id: group.id } if group_flag && !supplier.blank?
            can :read, DebitNote, warehouse_id: warehouse.id unless warehouse.blank?
            can :read, DebitNote, warehouse: { group_id: group.id } if group_flag && !warehouse.blank?
            can :print, :debit_note
            can :print, DebitNote, supplier_id: supplier.id unless supplier.blank?
            can :print, DebitNote, supplier: { group_id: group.id } if group_flag && !supplier.blank?
            can :print, DebitNote, warehouse_id: warehouse.id unless warehouse.blank?
            can :print, DebitNote, warehouse: { group_id: group.id } if group_flag && !warehouse.blank?
          when 'get_dispute_debit_note'
            can :get_dispute_debit_note, :debit_note
            can :get_take_action, :debit_note
            can :get_dispute_debit_note, DebitNote, supplier_id: supplier.id unless supplier.blank?
            can :get_dispute_debit_note, DebitNote, supplier: { group_id: group.id } if !supplier.blank? && group_flag
            can :get_dispute_debit_note, DebitNote, warehouse_id: warehouse.id unless warehouse.blank?
            can :get_dispute_debit_note, DebitNote, warehouse: { group_id: group.id } if group_flag && !warehouse.blank?
          when 'get_revision_debit_note'
            can :get_revision_debit_note, :debit_note
            can :get_take_action, :debit_note
            can :get_revision_debit_note, DebitNote, supplier_id: supplier.id unless supplier.blank?
            can :get_revision_debit_note, DebitNote, supplier: { group_id: group.id } if !supplier.blank? && group_flag
            can :get_revision_debit_note, DebitNote, warehouse_id: warehouse.id unless warehouse.blank?
            can :get_revision_debit_note, DebitNote, warehouse: { group_id: group.id } if group_flag && !warehouse.blank?
          when 'get_accept_debit_note'
            can :get_accept_debit_note, :debit_note
            can :get_take_action, :debit_note
            can :get_accept_debit_note, DebitNote, supplier_id: supplier.id unless supplier.blank?
            can :get_accept_debit_note, DebitNote, supplier: { group_id: group.id } if !supplier.blank? && group_flag
            can :get_accept_debit_note, DebitNote, warehouse_id: warehouse.id unless warehouse.blank?
            can :get_accept_debit_note, DebitNote, warehouse: { group_id: group.id } if group_flag && !warehouse.blank?
          when 'get_reject_debit_note'
            can :get_reject_debit_note, :debit_note
            can :get_take_action, :debit_note
          when 'synch'
            can :synch, :debit_note
            can :synch, DebitNote, warehouse_id: warehouse.id unless warehouse.blank?
            can :synch, DebitNote, warehouse: { group_id: group.id } if group_flag && !warehouse.blank?
            can :synch_new_payment_debit_note, :debit_note
            can :synch_new_payment_debit_note, DebitNote, warehouse_id: warehouse.id unless warehouse.blank?
            can :synch_new_payment_debit_note, DebitNote, warehouse: { group_id: group.id } if group_flag && !warehouse.blank?
          else
            can feature.key.to_sym, :debit_note
            can :get_take_action, DebitNote
          end
        when 'PaymentVoucher'
          case feature.key
          when 'index', 'show'
            can :read, :payment_voucher
            can :read, PaymentVoucher, supplier_id: supplier.id unless supplier.blank?
            can :read, PaymentVoucher, supplier: { group_id: group.id } if group_flag && !supplier.blank?
            can :read, PaymentVoucher, warehouse_id: warehouse.id unless warehouse.blank?
            can :read, PaymentVoucher, warehouse: { group_id: group.id } if group_flag && !warehouse.blank?
          when 'new', 'create'
            can :make, :payment_voucher
            can :make, PaymentVoucher, warehouse_id: warehouse.id unless warehouse.blank?
            can :make, PaymentVoucher, warehouse: { group_id: group.id } if group_flag && !warehouse.blank?
            can :make, PaymentVoucher, supplier_id: supplier.id unless supplier.blank?
            can :make, PaymentVoucher, supplier: { group_id: group.id } if group_flag && !supplier.blank?
            can :get_invoice_based_on_supplier, :payment_voucher
            can :get_invoice_based_on_supplier, PaymentVoucher, warehouse_id: warehouse.id unless warehouse.blank?
          when 'approve_invoice'
            can :approve_invoice, :payment_voucher
            can :approve_invoice, PaymentVoucher, warehouse_id: warehouse.id unless warehouse.blank?
            can :approve_invoice, PaymentVoucher, warehouse: { group_id: group.id } if group_flag && !warehouse.blank?
            can :approve_invoice, PaymentVoucher, supplier_id: supplier.id unless supplier.blank?
            can :approve_invoice, PaymentVoucher, supplier: { group_id: group.id } if group_flag && !supplier.blank?
          when 'print_from_empo'
            can :print_from_empo, :payment_voucher
            can :print_from_empo, PaymentVoucher, warehouse_id: warehouse.id unless warehouse.blank?
            can :print_from_empo, PaymentVoucher, warehouse: { group_id: group.id } if group_flag && !warehouse.blank?
          when 'print_from_supplier'
            can :print_from_supplier, :payment_voucher
            can :print_from_supplier, PaymentVoucher, supplier_id: supplier.id unless supplier.blank?
            can :print_from_supplier, PaymentVoucher, supplier: { group_id: group.id } if group_flag && !supplier.blank?
          else
            can feature.key.to_sym, :payment_voucher
            can feature.key.to_sym, PaymentVoucher
          end
        when 'Payment'
          case feature.key
          when 'index', 'show'
            can :read, :payment
            can :read, Payment, supplier_id: supplier.id unless supplier.blank?
            can :read, Payment, supplier: { group_id: group.id } if group_flag && !supplier.blank?
            can :read, Payment, warehouse_id: warehouse.id unless warehouse.blank?
            can :read, Payment, warehouse: { group_id: group.id } if group_flag && !warehouse.blank?
          when 'create', 'new'
            can :make, :payment
            can :make, Payment
            can :search_pv, :payment
            can :search_dn, :payment
          when 'accept'
            can :accept, :payment
            can :accept, Payment.with_state(:pending), supplier_id: supplier.id unless supplier.blank?
            can :accept, Payment.with_state(:pending), supplier: { group_id: group.id } if group_flag && !supplier.blank?
            can :accept, Payment.with_state(:pending), warehouse_id: warehouse.id unless warehouse.blank?
            can :accept, Payment.with_state(:pending), warehouse: { group_id: group.id } if group_flag && !warehouse.blank?
          when 'reject'
            can :reject, :payment
            can :reject, Payment.with_state(:pending), supplier_id: supplier.id unless supplier.blank?
            can :reject, Payment.with_state(:pending), supplier: { group_id: group.id } if group_flag && !supplier.blank?
            can :reject, Payment.with_state(:pending), warehouse_id: warehouse.id unless warehouse.blank?
            can :reject, Payment.with_state(:pending), warehouse: { group_id: group.id } if group_flag && !warehouse.blank?
          when 'print'
            can :print, Payment, supplier_id: supplier.id unless supplier.blank?
            can :print, Payment, supplier: { group_id: group.id } if group_flag && !supplier.blank?
            can :print, Payment, warehouse_id: warehouse.id unless warehouse.blank?
          else
            can feature.key.to_sym, :payment
            can feature.key.to_sym, Payment
          end
        when 'ReturnedProces'
          case feature.key
          when 'index', 'show'
            can :read, :returned_process
            can :read, ReturnedProcess, purchase_order: { supplier_id: supplier.id } unless supplier.blank?
            can :read, ReturnedProcess, purchase_order: { supplier: { group_id: group.id } } if group_flag && !supplier.blank?
            can :read, ReturnedProcess, purchase_order: { warehouse: { group_id: group.id } } if group_flag && !warehouse.blank?
            can :read, ReturnedProcess, purchase_order: { warehouse_id: warehouse.id } unless warehouse.blank?
            can :print_detail, :returned_process
            can :print_detail, ReturnedProcess, purchase_order: { supplier_id: supplier.id } unless supplier.blank?
            can :print_detail, ReturnedProcess, purchase_order: { supplier: { group_id: group.id } } if group_flag && !supplier.blank?
            can :print_detail, ReturnedProcess, purchase_order: { warehouse: { group_id: group.id } } if group_flag && !warehouse.blank?
            can :print_detail, ReturnedProcess, purchase_order: { warehouse_id: warehouse.id } unless warehouse.blank?

          when 'new_receive_retur', 'create_receive_retur'
            can :receive_retur, :returned_process
            can :receive_retur, ReturnedProcess, purchase_order: { supplier_id: supplier.id } unless supplier.blank?
            can :receive_retur, ReturnedProcess, purchase_order: { supplier: { group_id: group.id } } if group_flag && !supplier.blank?
            can :receive_retur, ReturnedProcess, purchase_order: { warehouse: { group_id: group.id } } if group_flag && !warehouse.blank?
            can :receive_retur, ReturnedProcess, purchase_order: { warehouse_id: warehouse.id } unless warehouse.blank?
          when 'new_dispute_retur', 'create_disputed_retur'
            can :make_dispute_retur, :returned_process
            can :make_dispute_retur, ReturnedProcess, purchase_order: { supplier_id: supplier.id } unless supplier.blank?
            can :make_dispute_retur, ReturnedProcess, purchase_order: { supplier: { group_id: group.id } }  if group_flag && !supplier.blank?
            can :make_dispute_retur, ReturnedProcess, purchase_order: { warehouse_id: warehouse.id } unless warehouse.blank?
            can :make_dispute_retur, ReturnedProcess, purchase_order: { warehouse: { group_id: group.id } } if group_flag && !warehouse.blank?
          when 'new_revise_retur', 'create_revised_retur'
            can :make_revise_retur, :returned_process
            can :make_revise_retur, ReturnedProcess, purchase_order: { supplier_id: supplier.id } unless supplier.blank?
            can :make_revise_retur, ReturnedProcess, purchase_order: { supplier: { group_id: group.id } } if group_flag && !supplier.blank?
            can :make_revise_retur, ReturnedProcess, purchase_order: { warehouse_id: warehouse.id } unless warehouse.blank?
            can :make_revise_retur, ReturnedProcess, purchase_order: { warehouse: { group_id: group.id } } if group_flag && !warehouse.blank?
          when 'accept_retur'
            can :accept_retur, :returned_process
            can :accept_retur, ReturnedProcess, purchase_order: { warehouse_id: warehouse.id } unless warehouse.blank?
            can :accept_retur, ReturnedProcess, purchase_order: { warehouse: { group_id: group.id } } if group_flag && !warehouse.blank?
            can :accept_retur, ReturnedProcess, purchase_order: { supplier_id: supplier.id } unless supplier.blank?
            can :accept_retur, ReturnedProcess, purchase_order: { supplier: { group_id: group.id } } if group_flag && !supplier.blank?
          when 'get_retur_history'
            can :read_retur_history, :returned_process
            can :read_retur_history, ReturnedProcess
          when 'synch'
            can :synch, :returned_process
            can :synch, ReturnedProcess, purchase_order: { warehouse_id: warehouse.id } unless warehouse.blank?
            can :synch, ReturnedProcess, purchase_order: { warehouse: { group_id: group.id } } if group_flag && !warehouse.blank?
            can :synch, ReturnedProcess, purchase_order: { supplier_id: supplier.id } unless supplier.blank?
            can :synch, ReturnedProcess, purchase_order: { supplier: { group_id: group.id } } if group_flag && !supplier.blank?
          else
            can feature.key.to_sym, :returned_process
            can feature.key.to_sym, ReturnedProcess
          end
        when 'EarlyPaymentRequest'
          case feature.key
          when 'index', 'show'
            can [:read, :show_detail_bank], :early_payment_request
            can [:print, :print_early_payment_request_with_bank], :early_payment_request
            can :read, EarlyPaymentRequest, purchase_order: { supplier_id: supplier.id } unless supplier.blank?
            can :read, EarlyPaymentRequest, purchase_order: { supplier: { group_id: group.id } } if group_flag && !supplier.blank?
            can :read, EarlyPaymentRequest, purchase_order: { warehouse_id: warehouse.id } unless warehouse.blank?
            can :read, EarlyPaymentRequest, purchase_order: { warehouse: { group_id: group.id } } if group_flag && !warehouse.blank?
          when 'send_payment_request'
            can :send_payment_request, :early_payment_request
            can :send_payment_request, EarlyPaymentRequest
          when 'reject_payment_request'
            can :reject_payment_request, :early_payment_request
            can :reject_payment_request, EarlyPaymentRequest
          when 'accept_payment_request'
            can :accept_payment_request, :early_payment_request
            can :new_detail_bank, :early_payment_request
            can :create_detail_bank, :early_payment_request
            can :accept_payment_request, EarlyPaymentRequest
            can :new_detail_bank, EarlyPaymentRequest
            can :create_detail_bank, EarlyPaymentRequest
          when 'print'
            can :print, :early_payment_request
            can :print, EarlyPaymentRequest
          when 'print_early_payment_request_with_bank'
            can :print_early_payment_request_with_bank, :early_payment_request
            can :print_early_payment_request_with_bank, EarlyPaymentRequest
            end
        when 'Company'
          case feature.key
          when 'index', 'show'
            can :read, :company
            can :read, Company
          when 'edit', 'update'
            can :modify, :company
            can [:edit, :update], Company
          else
            can feature.key.to_sym, feature.regulator.constantize
          end
        when 'User'
          case feature.key
          when 'index', 'show'
            can :read, :user
            can :read, User, supplier: { id: supplier.id } unless supplier.blank?
            can :read, User, supplier: { group_id: group.id } if group_flag && !supplier.blank?
            can :read, User, warehouse: { id: warehouse.id } unless warehouse.blank?
            can :read, User, warehouse: { group_id: group.id } if group_flag && !warehouse.blank?
          when 'change_password', 'update_password'
            can :edit_password, User, id: user.id if user.user_type == 'b2b'
          when 'new', 'create'
            can :make, :user
            can [:new, :create, :check_is_supplier, :edit, :update, :select_supplier_or_warehouse], User
            can [:read], TypeOfUser, users: { type_of_user_id: user.type_of_user.id }
          when 'edit', 'update'
            can :modify, :user
            can :modify, User
          when 'select_supplier_or_warehouse'
            can :select_supplier_or_warehouse, :user
          when 'change_email_notif', 'update_change_email_notif'
            can [:change_email_notif, :update_change_email_notif], User, id: user.id
          when 'change_activation'
            can :change_activation, :user if user.has_role?('superadmin') || group_flag
            can :change_activation, User if user.has_role?('superadmin')
            can :change_activation, User, supplier: { group_id: group.id }
            can :change_activation, User, warehouse: { group_id: group.id }
          when 'features'
            can :features, :user if user.has_role?('superadmin') || group_flag
            can :features, User if user.has_role?('superadmin')
            can :features, User, supplier: { group_id: group.id }
            can :features, User, warehouse: { group_id: group.id }
            can :update_features, :role
            can :update_features, :user if user.has_role?('superadmin') || group_flag
  #          can :update_features, User if user.has_role?('superadmin')
 #           can :update_features, User, supplier: { group_id: group.id }
#            can :update_features, User, warehouse: { group_id: group.id }
          else
            can feature.key.to_sym, :user
          end
        when 'ServiceLevel'
          case feature.key
          when 'index', 'show'
            can :read, :service_level
            can :read, ServiceLevel
          when 'new', 'create'
            can :make, :service_level
            can :make, ServiceLevel
          when 'edit', 'update'
            can :modify, ServiceLevel
          when 'destroy'
            can :destroy, :service_level
            can :destroy, ServiceLevel
          else
            can feature.key.to_sym, feature.regulator.constantize
          end
        when 'LdapSetting'
          case feature.key
          when 'new', 'create'
            unless warehouse.blank?
              can :read, :ldap_setting
              can :read, LdapSetting
              can :make, LdapSetting
            end
          else
            can feature.key.to_sym, feature.regulator.constantize
          end
        when 'Notification'
          case feature.key
          when 'index'
            can :read, :notification
            can :read, Notification, suppliers_notifications: { supplier_id: supplier.id } unless supplier.blank?
            can :read, Notification unless warehouse.blank?
            can :read, :notification unless warehouse.blank?
            can :short_notif, :notification
            can :short_notif, Notification, suppliers_notifications: { supplier_id: supplier.id } unless supplier.blank?
            can :show_notif, :notification
            can :show_notif, Notification, suppliers_notifications: { supplier_id: supplier.id } unless supplier.blank?
            can :change_notif_state, :notification
            can :change_notif_state, Notification, suppliers_notifications: { supplier_id: supplier.id } unless supplier.blank?
          when 'create'
            can :make, :notification
            can :make, Notification
          end
        when 'EmailNotification'
          case feature.key
          when 'show', 'index'
            can :read, :email_notification
            can :read, EmailNotification
          when 'load_email_form', 'update', 'edit'
            can [:load_email_form, :update], :email_notification
            can [:load_email_form, :update], EmailNotification
          else
            can feature.key.to_sym, feature.regulator.constantize
          end
        when 'Role'
          case feature.key
          when 'index', 'show'
            can :read, :role
            can :read, Role, parent_id: user.roles.pluck(:parent_id) unless supplier.blank?
            can :read, Role, name: 'supplier' unless supplier.blank?
            can :read, Role, name: 'customer' unless warehouse.blank?
            can :read, Role, parent_id: user.roles.pluck(:parent_id) unless warehouse.blank?
          when 'new', 'create'
            can :make, :role
            can :make, Role
          when 'edit', 'update'
            can :modify, Role, id: user.roles.pluck(:id)
          else
            can feature.key.to_sym, feature.regulator.constantize
          end
        when 'TypeOfUser'
          case feature.key
          when 'index', 'show'
            can :read, :type_of_user
            can :read, TypeOfUser, id: user.type_of_user_id unless warehouse.blank? || supplier.blank?
          when 'edit', 'update'
            can :modify, :type_of_user
            can :modify, TypeOfUser unless warehouse.blank?
            can :get_this_company, :type_of_user
            can :read, Company
          else
            can feature.key.to_sym, feature.regulator.constantize
          end
        when 'ApiSetting'
          case feature.key
          when 'create'
            can :make, :api_setting
            can :make, ApiSetting
          end
        when 'UserLog'
          case feature.key
          when 'index'
            can :read, :user_log
          when 'login_history'
            if supplier.present?
              can :read, UserLog, log_type: nil, user: { supplier_id: supplier.id } if supplier
              can :read, UserLog, log_type: nil, user: { supplier: { group_id: group.id } } if supplier
            elsif warehouse.present?
              can :read, UserLog, log_type: nil, user: { warehouse_id: warehouse.id } if warehouse
              can :read, UserLog, log_type: nil, user: { warehouse: { group_id: group.id } } if warehouse
              end
            can :login_history, :user_log
            if supplier.present?
              can :login_history, UserLog, log_type: nil, user: { supplier_id: supplier.id } if supplier
              can :login_history, UserLog, log_type: nil, user: { supplier: { group_id: group.id } } if supplier
            elsif warehouse.present?
              can :login_history, UserLog, log_type: nil, user: { warehouse_id: warehouse.id } if warehouse
              can :login_history, UserLog, log_type: nil, user: { warehouse: { group_id: group.id } } if warehouse
            end
          when 'transaction_history'
            can :transaction_history, :user_log
            can :read, UserLog # , :log_type => "PurchaseOrder"
            can :transaction_history, UserLog # , :log_type => "PurchaseOrder", :log_id => PurchaseOrder.joins(:supplier => :group).where("groups.id = ?", group.id).pluck(:id)
          # can :read, UserLog, :log_type => "PaymentVoucher", :log_id => PaymentVoucher.joins(:supplier => :group).where("groups.id = ?", group.id).pluck(:id)
          # can :read, UserLog, :log_type => "DebitNote", :log_id => DebitNote.joins(:supplier => :group).where("groups.id = ?", group.id).pluck(:id)
          # can :read, UserLog, :log_type => "EarlyPaymentRequest", :log_id => EarlyPaymentRequest.joins(:purchase_order => {:supplier => :group}).where("groups.id = ?", group.id).pluck(:id)
          # can :read, UserLog, :log_type => "ReturnedProcess", :log_id => ReturnedProcess.joins(:purchase_order => {:supplier => :group}).where("groups.id = ?", group.id).pluck(:id)
          # elsif group_flag && warehouse.present?
          ##  can :read, UserLog, :log_type => "PurchaseOrder", :log_id => PurchaseOrder.joins(:warehouse => :group).where("groups.id = ?", group.id).pluck(:id)
          #  can :read, UserLog, :log_type => "PaymentVoucher", :log_id => PaymentVoucher.joins(:warehouse => :group).where("groups.id = ?", group.id).pluck(:id)
          #  can :read, UserLog, :log_type => "DebitNote", :log_id => DebitNote.joins(:warehouse => :group).where("groups.id = ?", group.id).pluck(:id)
          #  can :read, UserLog, :log_type => "EarlyPaymentRequest", :log_id => EarlyPaymentRequest.joins(:purchase_order => {:warehouse => :group}).where("groups.id = ?", group.id).pluck(:id)
          #  can :read, UserLog, :log_type => "ReturnedProcess", :log_id => ReturnedProcess.joins(:purchase_order => {:warehouse => :group}).where("groups.id = ?", group.id).pluck(:id)
          # end
          else
            can feature.key.to_sym, feature.regulator.constantize
          end
        when 'Report'
          case feature.key
          when 'service_level_suppliers'
            can :service_level_suppliers, :report
          when 'on_going_disputes'
            can :on_going_disputes, :report
          when 'pending_deliveries'
            can :pending_deliveries, :report
          when 'returned_histories'
            can :returned_histories, :report
          end
        else
          can feature.key.to_sym, feature.regulator.constantize
        end
      end
        end
      end
    end

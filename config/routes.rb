B2bSystem::Application.routes.draw do
  devise_for :users, :path => '', :path_names => {:sign_in => 'login', :sign_up => "register"}
  as :user do
    get '/sign_out' => 'devise/sessions#destroy', :as => :destroy_user_session,
      :via => Devise.mappings[:user].sign_out_via
  end
  get 'get_autocomplete_state/:id'=>'application#get_autocomplete_state', :as=>:get_autocomplete_state
  get 'get_autocomplete_details/:type/:id'=>'application#get_autocomplete_details', :as=>:get_autocomplete_details
  get 'new_print/:id'=> 'application#new_print', :as => :new_print
  get 'print_list_po/:id' => 'application#print_list_po', :as => :print_list_po
  root :to => "dashboards#index"
  resources :suppliers_groups, :only => [:index,:show]
    get "generate_pdf_details_suppliers_group/:id" => "suppliers_groups#generate_pdf_details_suppliers_group", :as => :generate_pdf_details_suppliers_group
    get "generate_xls_details_suppliers_group/:id" => "suppliers_groups#generate_xls_details_suppliers_group", :as => :generate_xls_details_suppliers_group
    get 'change_level/:id'=> 'suppliers_groups#edit_level', :as=> :edit_level_supplier_group
    put 'update_level/:id'=> 'suppliers_groups#update_level', :as=> :update_level_supplier_group
    get 'synch_suppliers_based_on_group/:group_code' => 'suppliers_groups#synch_suppliers_based_on_group', :as => :synch_suppliers_based_on_group
    get "generate_pdf_all_sg" => "suppliers_groups#generate_pdf_all_sg", :as => :generate_pdf_all_sg
  resources :warehouses_groups, :only => [:index, :show]
    get "generate_xls_details_warehouses_group/:id" => "warehouses_groups#generate_xls_details_warehouses_group", :as => :generate_xls_details_warehouses_group
    get "generate_pdf_details_warehouses_group/:id" => "warehouses_groups#generate_pdf_details_warehouses_group", :as => :generate_pdf_details_warehouses_group
    get 'synch_warehouses_based_on_group/:group_code' => 'warehouses_groups#synch_warehouses_based_on_group', :as => :synch_warehouses_based_on_group
    get "generate_pdf_all_wg" => "warehouses_groups#generate_pdf_all_wg", :as => :generate_pdf_all_wg
  resources :dashboards, :only => [:index] do
    collection do
      get 'get_po_stats/:id/:year', :action=>'get_po_stats', :as=> :get_po_stats
      get 'get_dn_stats/:id/:year', :action=>'get_dn_stats', :as=> :get_dn_stats
      get 'report_purchase_order/:id/:date', :action => 'report_purchase_order', :as => :report_purchase_order
      get 'report_goods_receive_notes/:id/:date', :action => 'report_goods_receive_notes', :as => :report_goods_receive_notes
      get 'report_goods_receive_price_confirmations/:id/:date', :action => 'report_goods_receive_price_confirmations', :as => :report_goods_receive_price_confirmations
      get 'report_invoice/:id/:date', :action => 'report_invoice', :as => :report_invoice
      get 'report_goods_return_note/:id/:date', :action => 'report_goods_return_note', :as => :report_goods_return_note
      get 'report_debit_note/:id/:date', :action => 'report_debit_note', :as => :report_debit_note
      get 'count_disputed_po', :action=>'count_disputed_po', :as=> :count_disputed_po
      get 'count_disputed_dn', :action=>'count_disputed_dn', :as=> :count_disputed_dn
      get 'count_po_today_statuses', :action => 'count_po_today_statuses', :as => :count_po_today_statuses
      get 'for_sl_statistic', :action => 'for_sl_statistic', :as => :for_sl_statistic
      get 'get_all_po_status_statistic', :action => 'get_all_po_status_statistic', :as => :get_all_po_status_statistic
      get 'get_report', :action => "get_report", :as => :get_report
      get 'get_suppliers', :action => "get_suppliers", :as => :get_suppliers
      get 'get_service_level_flot_by_supplier/:supplier_id', :action => 'get_service_level_flot_by_supplier', :as => :get_service_level_flot_by_supplier
    end

    member do
      get 'detail_report_orders/:title', :action => 'detail_report_orders', :as => :report_order
      get 'detail_report_debit_note/:title', :action => 'detail_report_debit_note', :as => :report_debit_note
      get 'detail_report_return/:title', :action => 'detail_report_return', :as => :report_return
     end
  end
    get'get_tab_for/:id' => 'dashboards#get_tab_for', :as=>:get_tab_for

  resources :suppliers , :only => [:index, :show]
    get 'change_level/:id'=> 'suppliers#edit_level', :as=> :edit_level_supplier
    put 'update_level/:id'=> 'suppliers#update_level', :as=> :update_level_supplier
    get 'change_service/:id' => 'suppliers#edit_service_level', :as=> :edit_service_level_supplier
    put 'update_service_level/:id'=>'suppliers#update_service_level', :as=> :update_service_level_supplier
    get 'change_barcode_setting/:id'=> 'suppliers#edit_barcode_setting', :as=> :edit_barcode_setting_supplier
    put 'update_barcode_setting/:id'=> 'suppliers#update_barcode_setting', :as=> :update_barcode_setting_supplier
    get 'synch_suppliers_now' => 'suppliers#synch_suppliers_now', :as=> :synch_suppliers_now
    get 'synch_supplier_based_on_accountcode/:id' => "suppliers#synch_supplier_based_on_accountcode", :as => :synch_supplier_based_on_accountcode
  resources :products, :only => [:index, :show] do
    get "synch_product_based_on_code/:id" => "products#synch_product_based_on_code", :as => :synch_product_based_on_code
    collection do
      get 'synch_products_now' => 'products#synch_products_now', :as=>:synch_products_now
    end
  end
    get "generate_xls_details_product/:id" => "products#generate_xls_details_product", :as => :generate_xls_details_product
    get "generate_pdf_details_product/:id" => "products#generate_pdf_details_product", :as => :generate_pdf_details_product
    get "generate_pdf_all_prod" => "products#generate_pdf_all_prod", :as => :generate_pdf_all_prod

  namespace 'order_to_payments' do
    resources :purchase_orders, :only => [:index, :show] do
       collection do
         get 'synch_po_now'
       end
    end
      get "generate_pdf_all_po" => "purchase_orders#generate_pdf_all_po", :as => :generate_pdf_all_po
      get "generate_xls_details_po/:id" => "purchase_orders#generate_xls_details_po", :as => :generate_xls_details_po
      get "generate_pdf_details_po/:id" => "purchase_orders#generate_pdf_details_po", :as => :generate_pdf_details_po

    resources :advance_shipment_notifications, :only => [:index, :show, :edit, :update, :destroy]
      get 'new_asn/:id' => 'advance_shipment_notifications#new_asn',:as=> :new_asn
      get 'edit/:id' => 'advance_shipment_notifications#edit_asn',:as=> :edit_asn
      get 'destroy/:id' => 'advance_shipment_notifications#destroy',:as=> :destroy_asn
      post 'update/:id' => 'advance_shipment_notifications#update',:as=> :update_asn
      post 'create_asn/:id' => 'advance_shipment_notifications#create_asn', :as=> :create_asn
      get "generate_pdf_all_asn" => "advance_shipment_notifications#generate_pdf_all_asn", :as => :generate_pdf_all_asn
      get "generate_xls_details_asn/:id" => "advance_shipment_notifications#generate_xls_details_asn", :as => :generate_xls_details_asn
      get "generate_pdf_details_asn/:id" => "advance_shipment_notifications#generate_pdf_details_asn", :as => :generate_pdf_details_asn

    resources :goods_receive_notes, :only => [:index, :show]
      get 'serial/:id' => "goods_receive_notes#show_grn_serial", :as => :show_grn_serial
      get 'new_dispute_grn/:id' => 'goods_receive_notes#new_dispute_grn', :as=> :new_dispute_grn
      post 'create_dispute_grn/:id'=> 'goods_receive_notes#create_dispute_grn', :as=>:create_dispute_grn
      get 'new_revise_dispute_grn/:id'=>'goods_receive_notes#new_revise_dispute_grn', :as=>:new_revise_dispute_grn
      post 'create_revise_dispute_grn/:id'=>'goods_receive_notes#create_revise_dispute_grn', :as=>:create_revise_dispute_grn
      post 'accept_grn/:id/'=>'goods_receive_notes#accept_grn',:as=>:accept_grn
      get 'get_grn_history/:id'=>'goods_receive_notes#get_grn_history',:as=>:get_grn_history
      get 'synch_grn_now' => "goods_receive_notes#synch_grn_now", :as => :synch_grn_now
      get "generate_xls_details_grn/:id" => "goods_receive_notes#generate_xls_details_grn", :as => :generate_xls_details_grn
      get "generate_pdf_details_grn/:id" => "goods_receive_notes#generate_pdf_details_grn", :as => :generate_pdf_details_grn
      get "generate_pdf_all_grn" => "goods_receive_notes#generate_pdf_all_grn", :as => :generate_pdf_all_grn

    resources :goods_receive_price_confirmations, :only => [:index, :show]
      get 'new_dispute_grpc/:id' => 'goods_receive_price_confirmations#new_dispute_grpc', :as=> :new_dispute_grpc
      post 'create_dispute_grpc/:id'=> 'goods_receive_price_confirmations#create_dispute_grpc', :as=>:create_dispute_grpc
      get 'new_revise_dispute_grpc/:id'=>'goods_receive_price_confirmations#new_revise_dispute_grpc', :as=>:new_revise_dispute_grpc
      post 'create_revise_disputed_grpc/:id'=> 'goods_receive_price_confirmations#create_revise_disputed_grpc', :as=>:create_revise_disputed_grpc
      post 'accept_grpc/:id'=>'goods_receive_price_confirmations#accept_grpc',:as=>:accept_grpc
      get 'get_grpc_history/:id'=>'goods_receive_price_confirmations#get_grpc_history',:as=>:get_grpc_history
      get "generate_xls_details_grpc/:id" => "goods_receive_price_confirmations#generate_xls_details_grpc", :as => :generate_xls_details_grpc
      get "generate_pdf_details_grpc/:id" => "goods_receive_price_confirmations#generate_pdf_details_grpc", :as => :generate_pdf_details_grpc
      get "generate_pdf_all_grpc" => "goods_receive_price_confirmation#generate_pdf_all_grpc", :as => :generate_pdf_all_grpc

    resources :invoices, :only => [:index, :show]
      post 'print_inv/:id'=>'invoices#print_inv', :as=> :print_inv
      post 'respond_to_inv/:id'=>'invoices#respond_to_inv', :as => :respond_to_inv
      get 'print/:id'=>'invoices#print',:as=>:print
      get 'send_invoice_payment_request/:id' => "invoices#send_invoice_payment_request", :as => :create_payment_request
      get 'get_push_invoice_completed_to_api/:id' => "invoices#get_push_invoice_completed_to_api", :as => :get_push_invoice_completed_to_api
      get 'get_inv_history/:id'=>'invoices#get_inv_history',:as=>:get_inv_history
      get "generate_pdf_all_inv" => "invoices#generate_pdf_all_inv", :as => :generate_pdf_all_inv
      get "generate_xls_details_inv/:id" => "invoices#generate_xls_details_inv", :as => :generate_xls_details_inv
      get "generate_pdf_details_inv/:id" => "invoices#generate_pdf_details_inv", :as => :generate_pdf_details_inv
    resources :invoice_receipt_and_responses, :only => [:index, :show, :create]
    resources :debit_notes, :only => [:index, :show] do
      collection do
        get "synch"
        get "print"
      end

      member do
        post "get_dispute_debit_note/:from_action" => "debit_notes#get_dispute_debit_note", :as => :dispute_take_action
        post "get_revision_debit_note/:from_action" => "debit_notes#get_revision_debit_note", :as => :revision_take_action
        post "get_accept_debit_note/:from_action" => "debit_notes#get_accept_debit_note", :as => :accept_take_action
        post "get_reject_debit_note/:from_action" => "debit_notes#get_accept_debit_note", :as => :reject_take_action
        get "synch_new_payment_debit_note"
      end
    end
    get "generate_xls_details_dn/:id" => "debit_notes#generate_xls_details_dn", :as => :generate_xls_details_dn
    get "generate_pdf_details_dn/:id" => "debit_notes#generate_pdf_details_dn", :as => :generate_pdf_details_dn
    post 'accept_dn/:id/'=>'debit_notes#accept_dn',:as=>:accept_dn
    get 'new_dispute_dn/:id' => 'debit_notes#new_dispute_dn', :as=> :new_dispute_dn
    post 'create_dispute_dn/:id'=> 'debit_notes#create_dispute_dn', :as=>:create_dispute_dn
    get "generate_pdf_all_dn" => "debit_notes#generate_pdf_all_dn", :as => :generate_pdf_all_dn
    get 'get_dn_history/:id'=>'debit_notes#get_dn_history',:as=>:get_dn_history
    get 'new_revise_dispute_dn/:id'=>'debit_notes#new_revise_dispute_dn', :as=>:new_revise_dispute_dn
    post 'create_revise_dispute_dn/:id'=>'debit_notes#create_revise_dispute_dn', :as=>:create_revise_dispute_dn
  end

  namespace 'archives' do
    resources :purchase_orders, :only => [:index]
      get "generate_pdf_all_arc" => "purchase_orders#generate_pdf_all_arc"

    resources :advance_shipment_notifications, :only => [:index]
      get "generate_pdf_all_arc" => "advance_shipment_notifications#generate_pdf_all_arc"

    resources :goods_receive_notes, :only => [:index]
      get "generate_pdf_all_arc" => "goods_receive_notes#generate_pdf_all_arc"

    resources :goods_receive_price_confirmations, :only => [:index]
      get "generate_pdf_all_arc" => "goods_receive_price_confirmations#generate_pdf_all_arc"

    resources :invoices, :only => [:index]
      get "generate_pdf_all_arc" => "invoices#generate_pdf_all_arc"

    resources :debit_notes, :only => [:index]
      get "generate_pdf_all_arc" => "debit_notes#generate_pdf_all_arc"
  end

  resources :helps

  namespace 'setting' do
    resources :logo_companies, :except => [:index, :show, :destroy]
    resources :brand_companies, :except => [:index, :show, :destroy]
    resources :roles, :only => [:index, :show, :create, :update, :new, :edit] do
      collection do
        put 'update_features/:id', :action=>'update_features', :as=>:update_features
      end
    end

    resources :service_scheduler_apis do
      collection do
        get 'get_type_time' => "service_scheduler_apis#get_type_time"
      end
    end

    resources :image_blasts

    resources :dispute_settings#, :only => [:index, :new, :create, :edit, :update]

    resources :general_settings
    match 'general_settings/update_all' => 'general_settings#update_all', :as => :update_all, :via => :put

    resources :users, :only => [:index, :show, :create, :new, :edit, :update] do
      collection do
        get 'select_suppliers'
        get 'select_warehouses'
        get 'get_supplier'
        get 'check_is_supplier'
        get 'change_email_notif/:id', :action=>'change_email_notif', :as=>:change_email_notif
        put 'update_change_email_notif/:id',:action=>'update_change_email_notif', :as=>:update_change_email_notif
        put 'update_features/:id', :action=>'update_features', :as=>:update_features
        get 'mutation/:id', :action => 'mutation', :as => :mutation
        get 'update_mutation/:id', :action => 'update_mutation', :as => :update_mutation
        get 'force_logout', :action => 'force_logout', :as => :force_logout
      end

      member do
        get 'features'
      end
    end
    get 'select_supplier_or_warehouse/:key' => 'users#select_supplier_or_warehouse', :as=>:select_supplier_or_warehouse

    resources :user_level_disputes
    resources :type_of_users, :only => [:index, :edit, :update] do
      collection do
        get "get_this_company"
      end
    end

    resources :features, :only => [:index, :show, :create, :update, :edit, :destroy, :new]
    #resources :level_limits, :only => [:new, :create]
    resources :ldap_settings, :only => [:new, :create]
    resources :api_settings, :only => [:new, :create]
    resources :supplier_levels, :only => [:new, :create]
    resources :service_levels, :only=>[:index, :new,:create,:edit,:update,:destroy]
    get 'change_password/:id' => 'users#change_password', :as => :change_password_user
    put 'update_password/:id'=>'users#update_password', :as=> :update_password_user
    put 'change_activation/:id'=>'users#change_activation', :as=> :change_activation
    resources :companies, :only=>[:index,:new,:create,:edit,:update]

    resources :email_notifications, :only=>[:index,:update]  do
      collection do
        get 'load_email_form/:email_type' => "email_notifications#load_email_form"
      end
    end

    resources  :user_logs, :only => [:index] do
      collection do
        get "login_history"
        get "transaction_history"
      end
    end
  end

  resources :notifications do
    collection do
      get 'show_notif/:sn_id', :action=>'show_notif', :as=>:show_notif
      get 'my_notification/:id', :action => 'my_notification', :as => :my_notification
    end
  end
  get "generate_xls_details_notification/:id" => "notifications#generate_xls_details_notification", :as => :generate_xls_details_notification
  get "generate_pdf_details_notification/:id" => "notifications#generate_pdf_details_notification", :as => :generate_pdf_details_notification

  resources :payment_vouchers, :only => [:index, :show, :new, :create]
  get "generate_xls_details_voucher/:id" => "payment_vouchers#generate_xls_details_voucher", :as => :generate_xls_details_voucher
  get "generate_pdf_details_voucher/:id" => "payment_vouchers#generate_pdf_details_voucher", :as => :generate_pdf_details_voucher
  get "payment_vouchers/get_invoice_based_on_supplier/:supplier_name" => "payment_vouchers#get_invoice_based_on_supplier", :as => :get_invoice_based_on_supplier
  post "payment_vouchers/approve_invoice/:id" => "payment_vouchers#approve_invoice", :as => :get_approval_invoice
  get "payment_vouchers/print_from_empo/:id" => "payment_vouchers#print_from_empo", :as => :get_print_from_empo
  get "payment_vouchers/print_from_supplier/:id" => "payment_vouchers#print_from_supplier", :as => :get_print_from_supplier
  get "generate_pdf_all_pv" => "payment_vouchers#generate_pdf_all_pv", :as => :generate_pdf_all_pv
  get "need_approval" => "payment_vouchers#need_approval", :as => :need_approval

  namespace :api do
    namespace :v1 do
      get "/suppliers" => "suppliers#callback_suppliers"
      get "/po_forever" => "purchase_orders#po_forever"
      get "/po_details" => "detail_purchase_orders#callback_podetails"
      get "/addresses" => "name_and_addresses#callback_addresses"
      get "/customers" => "customers#callback_customers"
      get "/products" => "products#callback_products"
      get "/products_suppliers"=>"products_suppliers#callback_products_suppliers"
    end
  end

  resources :returned_processes, :only => [:index, :show] do
    collection do
      get 'new_dispute_retur/:id', :action=>'new_dispute_retur', :as=>:new_dispute_retur
      post 'create_disputed_retur/:id', :action=> 'create_disputed_retur', :as=>:create_disputed_retur
      get 'new_receive_retur/:id', :action=>'new_receive_retur', :as=>:new_receive_retur
      post 'create_receive_retur/:id', :action=>'create_receive_retur', :as=>:create_receive_retur
      get 'new_revise_retur/:id',:action=>'new_revise_retur', :as=>:new_revise_retur
      post 'create_revised_retur/:id',:action=>'create_revised_retur',:as=> :create_revised_retur
      get 'get_retur_history/:id', :action=>'get_retur_history', :as=>:get_retur_history
      get 'synch', :action => 'synch', :as => :synch
    end

    member do
      get "generate_xls_details_grtn"
      get "generate_pdf_details_grtn"
      get "print_detail"
      put 'accept_retur'
    end
  end

  get "generate_pdf_all_rp" => "returned_processes#generate_pdf_all_rp", :as => :generate_pdf_all_rp
  get 'short_notif' => 'notifications#short_notif', :as=> :short_notif
  get 'change_notif_state/:sn_id' => 'notifications#change_notif_state',:as=> :change_notif_state

  resources :warehouses , :only => [:index, :show] do
     collection do
       get 'synch_warehouses_now', :action=>'synch_warehouses_now',:as=>:synch_warehouses_now
     end
  end
    get 'warehouses/edit_level_limit/:warehouse_id' => 'warehouses#edit_level_limit', :as=> :edit_level_limit_warehouse
    put 'warehouses/update_level_limit/:warehouse_id'=>'warehouses#update_level_limit', :as=> :update_level_limit_warehouse

    get 'warehouses/set_area/:warehouse_id' => 'warehouses#set_area', :as=> :set_area
    get 'warehouses/update_area/:warehouse_id/:area_id'=>'warehouses#update_area', :as=> :update_area
    get 'warehouses/edit_email_notification/:warehouse_id' => 'warehouses#edit_email_notification', :as=> :edit_email_notification_warehouse
    post 'warehouses/update_email_notification/:warehouse_id' =>'warehouses#update_email_notification', :as=> :update_email_notification_warehouse
    get 'warehouses/synch_warehouse_based_on_code/:id' => 'warehouses#synch_warehouse_based_on_code', :as => :synch_warehouse_based_on_code

  resources :early_payment_requests, :only => [:index] do
    member do
      get "send_payment_request"
      get "accept_payment_request"
      get "reject_payment_request"
      get "new_detail_bank"
      post "create_detail_bank"
      get "show_detail_bank"
      get "print_early_payment_request_with_bank"
    end

    collection do
      get "print"
    end
  end
    get "generate_pdf_all_epr" => "early_payment_requests#generate_pdf_all_epr", :as => :generate_pdf_all_epr

  resources :payments, :only => [:index, :show, :new, :create] do
    member do
      get "accept", :action => "accept", :as => :accept
      get "reject", :action => "reject", :as => :reject
      get "print", :action => "print", :as => :print
    end
    collection do
      get "search_pv", :action => "search_pv", :as => :search_pv
      get "search_dn/:supplier", :action => "search_dn", :as => :search_dn, :constraints => { :supplier => /[^\/]+/ }
      get "search_retur/:supplier", :action => "search_retur", :as => :search_retur, :constraints => { :supplier => /[^\/]+/ }
    end
  end
    get "generate_pdf_all_pay" => "payments#generate_pdf_all_pay", :as => :generate_pdf_all_pay
    get "need_approval" => "payments#need_approval", :as => :need_approval
    get "generate_xls_details_payment/:id" => "payments#generate_xls_details_payment", :as => :generate_xls_details_payment

  resources :reports, :except => [:index, :show, :edit, :destroy, :update, :create, :new] do
    collection do
      get "service_level_suppliers"
      get "on_going_disputes/:type", :action => "on_going_disputes", :as => :on_going_disputes
      get "pending_deliveries"
      get "returned_histories"
      get "account_payable"
      get "payment_progress"
      get "account_receivable"
      get "print_to_xls/:from", :action => "print_to_xls", :as => :print_to_xls
      get "print_to_pdf/:from", :action => "print_to_pdf", :as => :print_to_pdf
    end

    member do
      get "on_going_dispute_details/:type", :action => "on_going_dispute_details", :as => :on_going_dispute_details
      get "returned_history_details"
      get "pending_delivery_details"
    end
  end
  get "generate_xls_details_sls/:id" => "reports#generate_xls_details_sls", :as => :generate_xls_details_sls
  get "generate_pdf_details_sls/:id" => "reports#generate_pdf_details_sls", :as => :generate_pdf_details_sls
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end

class ProductsController < ApplicationController
  layout "main"
  add_breadcrumb 'Products Master Data', :products_path
  load_and_authorize_resource @results
  before_filter :find_product, :only=>[:show, :generate_pdf_details_product]

  def generate_xls_details_product
    send_file @product.export_to_xls["path"], :disposition => 'inline', :type => 'application/xls', :filename => "PRODUCT-#{@product.apn_number}.xls"
  end

  def generate_pdf_details_product
    show
    render :pdf => "Payment-#{@product.name}",
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'products/product.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def index
#    @results = Product.search(params).order("created_at DESC").accessible_by(current_ability).page params[:page]
    @results = Product.search(params).order("created_at DESC").accessible_by(current_ability)#.page params[:page]
    if (params["format"] == "xls")
      @results = Product.search(params).order("created_at DESC").accessible_by(current_ability)
    end
    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xls
    end
  end

  def generate_pdf_all_prod
      title = "PROD_ALL_#{Time.new.strftime('%d-%m-%Y')}"
      @results = Product.search(params).order("created_at DESC").accessible_by(current_ability)
      render :pdf => title,
      :disposition => 'inline',
      :layout=> 'layouts/order_to_payment.pdf.erb',
      :template => 'products/prod_all.pdf.erb',
      :page_size => 'A4',
      :lowquality => false
  end

  def show
    add_breadcrumb 'Detail Product', product_path(params[:id])
  	@product=Product.find_by_id(params[:id])
    @suppliers = @product.suppliers_products
  end

  #desc: melakukan synch product ke API berdasarkan data product yg ada, UPDATE
  def synch_product_based_on_code
    product_db = Product.find(params[:id]).callback_api_product_based_on_code
    status = eval_status_res(product_db)
    send_email_which_service_api_is_not_connected(status)
    respond_to do |f|
      f.js {render :layout => false, :status => status}
    end
  end

  #desc: melakukan synch product ke API
  def synch_products_now
    result = Product.synch_products_now
    status = eval_status_res(result)
    send_email_which_service_api_is_not_connected(status)
    respond_to do |f|
      @back_to_index = "#{products_path}"
      f.js {render :layout => false, :status => status}
    end
  end

  private
  def find_product
    @product=Product.find(params[:id])
    not_found if @product.nil?
  end
end

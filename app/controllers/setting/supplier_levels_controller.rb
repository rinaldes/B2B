class Setting::SupplierLevelsController < ApplicationController
  layout 'setting'

  def new
    add_breadcrumb 'Service Level Setting', :setting_companies_path
    @supplier_level = SupplierLevel.new
  end

  def create
    (1..3).each do |level|
      exists = SupplierLevel.where(:level => level).pluck(:supplier_level_detail_id)
      change = params[:supplier][level.to_s].keys.map{|v|v.to_i} rescue []
      add = change - exists
      del = exists - change

      SupplierLevel.where(:level => level, :supplier_level_detail_id => del).destroy_all if del.length > 0
      add.each do |v|
        SupplierLevel.new(:level => level, :supplier_level_detail_id => v).save
      end
    end

    redirect_to new_setting_supplier_level_path, :notice => "Supplier level setting saved"
  end
end

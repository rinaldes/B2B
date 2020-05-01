class AddAssetNameToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :asset_name, :string
  end
end

class ChangeLimitColumnOnSuppliers < ActiveRecord::Migration
  def up
    change_column :suppliers, :name, :string,:limit=>200
    change_column :suppliers, :account_code, :text,:limit=>200
    change_column :suppliers, :pay_to_code, :text, :limit=>200
    change_column :suppliers, :shortname, :text, :limit=>200
  end

  def down
  end
end

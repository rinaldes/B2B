class ChangeTypeColumnLevelSuppliersAtSuppliers < ActiveRecord::Migration
  def up
  	supplier = Supplier.connection.execute("UPDATE suppliers SET level = '0'")
    if supplier
    change_column :suppliers, :level, 'integer USING CAST(level AS integer)'
    end
  end

  def down
  end
end

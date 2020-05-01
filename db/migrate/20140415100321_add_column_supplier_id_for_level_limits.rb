class AddColumnSupplierIdForLevelLimits < ActiveRecord::Migration
  def up
    add_column :level_limits, :supplier_id, :integer
  end

  def down
    remove_column :level_limits, :supplier_id
  end
end

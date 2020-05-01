class ChangeRelationBetweenSlAndSupplier < ActiveRecord::Migration
  def up
  	add_column :suppliers, :service_level_id, :integer
  	add_column :suppliers, :service_level_total, :decimal
  	remove_column :service_levels, :supplier_id
  	rename_column :suppliers, :parent_id_id, :parent_id
  end

  def down
  end
end

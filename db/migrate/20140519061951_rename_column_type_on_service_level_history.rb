class RenameColumnTypeOnServiceLevelHistory < ActiveRecord::Migration
  def up
  	rename_column :service_level_histories, :type, :po_type
  end

  def down
  	rename_column :service_level_histories, :po_type, :type
  end
end

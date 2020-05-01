class AddTotalSlColumnToHistorySl < ActiveRecord::Migration
  def up
  	add_column :service_level_histories, :total_sl, :decimal, :precision=>6, :scale=>2
  end
  def down
    remove_column :service_level_histories, :total_sl
  end
end

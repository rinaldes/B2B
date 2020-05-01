class AddColumnStatusToOffsetApis < ActiveRecord::Migration
  def up
  	 add_column :offset_apis, :data_status, :boolean, :default=>false
  end
  def down
    remove_column :offset_apis, :data_status
  end
end

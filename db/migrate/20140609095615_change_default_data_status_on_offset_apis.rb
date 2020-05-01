class ChangeDefaultDataStatusOnOffsetApis < ActiveRecord::Migration
  def up
  	change_column :offset_apis, :data_status, :boolean, :default=>true
  	rename_column :offset_apis, :data_status, :availability_status
  end

  def down
     add_column :offset_apis, :data_status, :boolean, :default=>false
     rename_column :offset_apis, :availability_status,:data_status
  end
end

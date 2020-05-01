class Removemodelcolumnatfeatures < ActiveRecord::Migration
  def up
  end

  def down
  	remove_column :features, :model
  end
end

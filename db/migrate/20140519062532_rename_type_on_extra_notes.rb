class RenameTypeOnExtraNotes < ActiveRecord::Migration
  def up
    rename_column :extra_notes, :type, :en_type
  end

  def down
  	rename_column :extra_notes, :en_type, :type
  end
end

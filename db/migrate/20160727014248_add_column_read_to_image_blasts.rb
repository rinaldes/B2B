class AddColumnReadToImageBlasts < ActiveRecord::Migration
  def change
    add_column :image_blasts, :read, :boolean, :default => false
  end
end

class AddValidFromToNot < ActiveRecord::Migration
  def change
    add_column :notifications, :valid_from, :date
  end
end

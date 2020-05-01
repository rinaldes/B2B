class AddIsPublishedToDn < ActiveRecord::Migration
  def change
    add_column :debit_notes, :is_published, :boolean
    add_column :debit_notes, :is_completed, :boolean
  end
end

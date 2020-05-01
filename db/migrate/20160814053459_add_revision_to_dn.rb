class AddRevisionToDn < ActiveRecord::Migration
  def change
    add_column :debit_notes, :revision_to, :integer
  end
end

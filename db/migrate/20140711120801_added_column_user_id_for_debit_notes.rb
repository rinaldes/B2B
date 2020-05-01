class AddedColumnUserIdForDebitNotes < ActiveRecord::Migration
  def up
    add_column :debit_notes, :user_id, :integer
  end

  def down
    remove_column :debit_notes, :user_id
  end
end

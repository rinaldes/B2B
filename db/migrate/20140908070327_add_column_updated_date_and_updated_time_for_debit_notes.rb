class AddColumnUpdatedDateAndUpdatedTimeForDebitNotes < ActiveRecord::Migration
  def up
    add_column :debit_notes, :updated_date, :date
    add_column :debit_notes, :updated_time, :time
  end

  def down
    remove_column :debit_notes, :updated_date
    remove_column :debit_notes, :updated_time
  end
end

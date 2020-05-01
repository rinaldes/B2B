class AddColumnFinancialPeriodAndFinancialYearForDebitnotes < ActiveRecord::Migration
  def up
    add_column :debit_notes, :financial_period, :string
    add_column :debit_notes, :financial_year, :string
  end

  def down
    remove_column :debit_notes, :financial_period
    remove_column :debit_notes, :financial_year
  end
end

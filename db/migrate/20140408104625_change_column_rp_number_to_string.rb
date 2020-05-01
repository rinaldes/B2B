class ChangeColumnRpNumberToString < ActiveRecord::Migration
  def up
    change_column :returned_processes, :rp_number, 'varchar(20) USING CAST(rp_number AS varchar(20))'
  end

  def down
  end
end

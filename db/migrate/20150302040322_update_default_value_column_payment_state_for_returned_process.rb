class UpdateDefaultValueColumnPaymentStateForReturnedProcess < ActiveRecord::Migration
  def up
  	retur = ReturnedProcess.where("payment_state is null")
  	if retur.present?
  		returned_process = ReturnedProcess.find_by_sql("UPDATE returned_processes SET payment_state = 0 WHERE id in (#{retur.collect(&:id).join(',')})")
  	end
  end

  def down
  	returned_process = ReturnedProcess.find_by_sql("UPDATE returned_processes SET payment_state = null")
  end
end

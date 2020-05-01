module WarehousesHelper
	def limit_type(var)
		arr = ['grn','grpc','grtn']
		return arr[var]
	end

	def level_limit_name(var)
		arr = ['Goods Receive Notes', 'Goods Receive Price Confirmations', 'Goods return Note']
		return arr[var]
	end

	def title_level_limit(var)
		arr = { 'grn' => 'Goods Receive Notes', 'grpc' => 'Goods Receive Price Confirmations', 'grtn' => 'Goods return Note'}
		return arr[var]
	end
end

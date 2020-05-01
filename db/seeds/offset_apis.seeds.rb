if Rails.env.development? || Rails.env.staging? || Rails.env.production? || Rails.env.vmware?
  unless !OffsetApi.first.blank?
	  puts "create default offset for master apis"
	  7.times do |t|
	    case t
		    when 0
		      new_offset = OffsetApi.new(:api_type=>"#{PO}", :offset=>0)
		    when 1
		    	new_offset = OffsetApi.new(:api_type=>"Supplier", :offset=>0)
		    when 2
		    	new_offset = OffsetApi.new(:api_type=>"Warehouse", :offset=>0)
		    when 3
		    	new_offset = OffsetApi.new(:api_type=>"Product_Supplier", :offset=>0)
		    when 4
		    	new_offset = OffsetApi.new(:api_type=>"Product", :offset=>0)
		    when 5
		    	new_offset = OffsetApi.new(:api_type=>"#{GRN}", :offset=>0)
		    when 6
		    	new_offset = OffsetApi.new(:api_type=>"#{GRTN}", :offset=>0)
		end
	    if new_offset.save
	      puts "offset for apis has been created"
	    else
	      puts "an error has ocurred when saving offset for #{PO}"
	    end
	  end
  end
else
  puts "Do nothing"
end
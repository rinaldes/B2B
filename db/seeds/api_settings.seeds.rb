after :users do
    api = ApiSetting.first

    unless api
        puts "Create Default API Setting"
            puts "======================================"

            if Rails.env == "production"
                url = "http://10.10.11.2:8080/b2b/api/"
            elsif Rails.env == "vmware"
                url = "http://172.16.121.128:8080/b2b/api/"
            elsif Rails.env == "staging" || Rails.env == "development"
                url = "http://localhost:8080/b2b/api/"
            else
                url = "http://localhost:8080/b2b/api/"
            end
            api_setting = ApiSetting.new(
                :api => url,
                :password => "12345678",
                )
            if api_setting.save
                puts "Create Default API Setting Successfully"
                puts "======================================"
            end

            puts "Create Api Feature"
            puts "========================================"

            #api_feature = Feature.new(
            #   :name => "  Create",
            #   :key =>     "Setting::ApiSettings/create",
            #   :description => nil,
            #   :regulator => "ApiSetting"
            #   )
            #if api_feature.save
            #   puts "Create Default API Feature Successfully"
            #   puts "======================================"
            #end
    else
        puts "do nothing"
    end
end
module List_features

  def list_all_controller
    string = ''
      controllers = Rails.application.routes.routes.map do |route|
        {controller: route.defaults[:controller], action: route.defaults[:action]}
      end.uniq.compact
      names = []
      unless_controller = ["","Devise::Sessions","Devise::Registrations","Devise::Passwords"]
      controllers.each do |i|
        next if unless_controller.include?("#{i[:controller]}".camelize)
        string = "#{i[:controller]}".camelize
        string += "/#{i[:action]}"
        names << string
      end
    return names
  end

  def list_all_method
    string = ''
      methods = Rails.application.routes.routes.map do |route|
        {action: route.defaults[:action]}
      end.uniq.compact
      names = []
      methods.each do |i|
        string = "#{i[:action]}"
        names << string
      end
    return names
  end

  module_function :list_all_controller,:list_all_method

end


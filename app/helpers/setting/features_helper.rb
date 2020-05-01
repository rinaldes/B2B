module Setting::FeaturesHelper
  def check_path_feature(feature)
    return setting_features_path if params[:action] == "new" || params[:action] == "create"
    return setting_feature_path(feature) if params[:action] == "edit" || params[:action] == "update"
  end
end

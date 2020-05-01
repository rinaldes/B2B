class Feature < ActiveRecord::Base
  #validations
  include List_features
  extend  List_features

  before_save  { |feature| feature.regulator = feature.regulator.classify }
  avalaible_features= list_all_controller
  validates :name, presence: {message: "Feature name can't be blank", allow_blank: false, allow_nil: false},:allow_blank => true, length:{minimum: 3, message: "That is not even a name"}
  validates :key, presence: {message: "Feature access can't be blank", allow_blank: false, allow_nil: false}, allow_blank: true, inclusion: { :in=> avalaible_features, message: "%{value} is not in features, please select a feature that has been provided" }
  validates :regulator, :presence => {:message => "Feature regulator can't be blank", allow_blank: false, allow_nil: false}
  #validates :description, presence: {message: "Please describe the feature", allow_blank: false, allow_nil: false}, allow_blank: true, length: {minimum: 3, message: "More detailed, please"}
  has_many :users_features
  has_many :users, through: :users_features
  attr_accessible :name, :key, :description, :regulator
  paginates_per PER_PAGE
  max_paginates_per 100
   def self.search(options)
    unless options[:search].blank?
      if options[:search][:field].present?
        case options[:search][:field].downcase
        when 'name'
          where("name ilike ?", "%#{options[:search][:detail]}%")
        when "regulator"
          where("regulator ilike ?", "%#{options[:search][:detail]}%")
        end
      else
         where("name ilike ?", "%#{options[:search][:detail]}%")
      end
    else
      scoped
    end
  end
  def self.save_a_new_feature(params)
    unless params[:controller].blank? && params[:action].blank?
      feature = Feature.new(:name=>set_feature_name(params[:action]), :regulator => set_feature_regulator(params[:controller]), :key => set_feature_key(params))
      if feature.save
        return feature
      else
        return false
      end
    end
    return false
  end

  def self.set_feature_name(name)
    if name.split("_").count > 1
      case name
        when "count_po_today_statuses"
          name = "PO statuses today"
        when "for_sl_statistic"
          name = "Service level statistic"
        when "get_all_po_status_statistic"
          name = "Purchase orders statistic"
        else
          return name.split("_").join(" ").capitalize
      end
    end
    return name.capitalize
  end

  def self.set_feature_regulator(controller)
    if controller.split("/").count > 1
       return controller.split("/").last.classify
    else
      return controller.classify
    end
  end

  def self.set_feature_key(params)
     key = ''
     if params[:controller].split("/").count > 1
       key = "#{params[:controller].camelize}/#{params[:action]}"
     else
       key = "#{params[:controller].camelize}/#{params[:action]}"
     end
     return key
  end

end

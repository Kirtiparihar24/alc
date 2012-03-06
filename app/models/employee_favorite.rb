class EmployeeFavorite < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :url
  validates_presence_of :name
  before_save :format_name
  before_create :get_url
  validates_uniqueness_of :name, :scope => [:employee_user_id, :fav_type],:case_sensitive => false
  validates_uniqueness_of :url, :scope => [:employee_user_id, :fav_type],:case_sensitive => false
 
  
  def self.rss_entries_count(url)
    begin
      #    feed=Feedzirra::Feed.fetch_and_parse(url)
      #    unless (feed.nil? || feed==403 || feed==0 || feed==401 )
      #      return feed.entries.count
      #    else
      return 0
      #    end
    rescue Exception=>ex
      return 0
    end
  end

  def get_url
    if self.fav_type=="Internal"
      url = self.url.split("/")
      u = []
      url.each_with_index do |ul, index|
        if index > 2
          u << ul
        end
      end
      self.url = u.join("/")
    else
      if self.url[0..3]=='http'
        self.url
      else
        self.url= "http://" + self.url
      end
    end
  end
  
  def format_name
    self.name.capitalize!
  end

end

# == Schema Information
#
# Table name: employee_favorites
#
#  id               :integer         not null, primary key
#  fav_type         :string(255)
#  name             :string(255)
#  url              :text
#  controller_name  :string(255)
#  action_name      :string(255)
#  company_id       :integer
#  employee_user_id :integer
#  created_at       :datetime
#  updated_at       :datetime
#


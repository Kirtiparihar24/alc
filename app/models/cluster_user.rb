class ClusterUser < ActiveRecord::Base
  belongs_to :cluster
  belongs_to :user

  def self.skip_time_zone_conversion_for_attributes
    [:from_date, :to_date]
  end
  
  def self.find_cluster_user(cluster_id)
    all :conditions=>["cluster_users.cluster_id IN (?)", cluster_id], :include => [:user]
  end

end


# == Schema Information
#
# Table name: cluster_users
#
#  id         :integer         not null, primary key
#  user_id    :integer
#  cluster_id :integer
#  created_at :datetime
#  updated_at :datetime
#  from_date  :datetime
#  to_date    :datetime
#


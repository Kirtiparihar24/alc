class Cluster < ActiveRecord::Base
  #Type => { 1=>"Livian(Front Office)", 2=>"Back Office", 4=>"Common Pool"}  
  has_many :cluster_users
  has_many :users, :through=> :cluster_users
  validates_presence_of :name
  validates_presence_of :description  
  validates_uniqueness_of :name

  def livians
    self.users.all(:select => 'users.id,users.first_name, users.last_name',:include => [:service_provider], :conditions => ["users.id = service_providers.user_id"], :order => "users.first_name")
  end

  def lawyers
    self.users.all(:include => [:employee, :company], :conditions => ["users.id = employees.user_id"])
  end
  
  # returns cluster with eager loaded users that are employees
  def self.get_cluster_with_employees(cluster_id)
    first(:include => [:users => [:role, :company]], :conditions => ["clusters.id=? AND  roles.name = 'lawyer'", cluster_id])
  end

  # it return array of service_provider objects
  def all_employees
    ServiceProvider.all(:conditions => ["user_id IN (?)", self.users.map(&:id)])
  end

  def all_lawfirm_users
    Employee.all(:include => [:user], :order => "users.first_name ASC, users.last_name ASC", :conditions => ["user_id IN (?)", self.users.map(&:id)])
  end

  def is_front_office_cluster?
    self.cluster_type & 1 == 1
  end

  def is_common_pool_cluster?
    self.cluster_type & 4 == 4
  end

  def is_back_office_cluster?
    self.cluster_type & 2 == 2
  end

  def self.get_common_pool_livian_users
    livians, cp_clusters = [],common_pool_clusters
    for c in cp_clusters
      livians += c.livians
    end
    livians.uniq
  end

  def self.common_pool_clusters
    all(:conditions => "cluster_type IN (4,5,6,7)")
  end

  def self.back_office_clusters
    all(:conditions => "cluster_type IN (2,3,6,7)")
  end

  def self.get_back_office_cluster_livians
    livians, bo_clusters = [],back_office_clusters
    for c in bo_clusters
      livians += c.livians
    end
    livians.uniq
  end

  # updating type of the service provider
  def update_cluster_type(params)
    unless params[:type].blank?
      self.cluster_type = 0
      params[:type].each do|e|
        self.cluster_type |= e.to_i
      end
    else
      self.cluster_type = 1
    end
    self.save
  end

  def types_of_cluster
    type =[]
    if self.is_back_office_cluster?
      type << "Back Office"
    end
    if self.is_front_office_cluster?
      type << "Front Office"
    end
    if self.is_common_pool_cluster?
      type << "Common Pool"
    end

    type
  end

end

# == Schema Information
#
# Table name: clusters
#
#  id          :integer         not null, primary key
#  name        :string(15)
#  description :text
#


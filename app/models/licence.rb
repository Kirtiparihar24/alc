class Licence < ActiveRecord::Base
  belongs_to :product
  has_many :product_licences
  belongs_to:company
  
  def self.total_licence(company_id)
    licences = find_all_by_company_id(company_id, :include => :company, :conditions => ['expired_date >= ? OR expired_date IS NULL', Time.zone.now])
    tmp = 0
    licences.each do |obj|
      tmp += obj.licence_count
    end
    tmp
  end

  def self.total_licence_by_product(company_id, product_id)
    licences = find_all_by_company_id_and_product_id(company_id, product_id, :conditions => ['expired_date >= ?', Time.zone.now])
    tmp = 0
    licences.each do |obj|
      tmp += obj.licence_count
    end

    tmp
  end

end

# == Schema Information
#
# Table name: licences
#
#  id            :integer         not null, primary key
#  company_id    :integer         not null
#  product_id    :integer         not null
#  licence_count :integer         not null
#  cost          :integer         not null
#  start_date    :datetime        not null
#  expired_date  :datetime
#  created_at    :datetime
#  updated_at    :datetime
#


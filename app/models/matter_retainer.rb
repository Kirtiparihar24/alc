class MatterRetainer < ActiveRecord::Base
  default_scope :order => 'created_at DESC'
  attr_reader :STATUS
  belongs_to :matter
  belongs_to :financial_transaction

  validates_presence_of :date,:message=>:date_blank
  validates_presence_of :amount,:message=>:amount_blank
  validates_numericality_of :amount, :greater_than => 0, :message =>:amount_invalid,:allow_blank=>:true

  validate :retainer_date_cant_be_less_than_matter_inception
  validate :amount_length
  
  def retainer_date_cant_be_less_than_matter_inception
   self.errors.add(:date,:retainer_date) if self.date && self.matter[:matter_date] &&  self.date < self.matter[:matter_date].to_date
  end

  def get_document
    DocumentHome.first(:order => "created_at DESC", :conditions => ["mapable_type = ? AND mapable_id = ?", 'MatterRetainer', self.id])
  end

  def amount_length
    if (!self.amount.blank? && !self.errors.on(:amount) && self.amount.to_s.length > 10)
      self.errors.add(:amount, "maximum length 10")
    end
  end
end

# == Schema Information
#
# Table name: matter_retainers
#
#  id                 :integer         not null, primary key
#  date               :date
#  amount             :integer
#  remarks            :string(255)
#  matter_id          :integer
#  created_by_user_id :integer
#  updated_by_user_id :integer
#  company_id         :integer
#  created_at         :datetime
#  updated_at         :datetime
#


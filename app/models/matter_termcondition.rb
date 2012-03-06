class MatterTermcondition < ActiveRecord::Base
  belongs_to :matter
  acts_as_paranoid
  attr_accessor :from, :fixed_rate, :retainer_rate, :hourly_rate,:not_to_exceed,:asset_id,:document_home_id,:name,:bookmark,:phase,:privilege, :author, :description, :source, :employee_user_id,:file,:mapable_id

  validates_length_of :fixed_rate_amount, :maximum => 10, :allow_nil => true, :allow_blank => true
  validates_numericality_of :fixed_rate_amount, :greater_than => 0, :allow_blank => true

  validates_length_of :not_to_exceed_amount, :maximum => 10, :allow_nil => true, :allow_blank => true
  validates_numericality_of :not_to_exceed_amount, :greater_than => 0,  :allow_blank => true

  validates_length_of :retainer_amount, :maximum => 10, :allow_nil => true, :allow_blank => true
  validates_numericality_of :retainer_amount, :greater_than => 0, :allow_blank => true

  validates_length_of :min_trigger_amount, :maximum => 10, :allow_nil => true, :allow_blank => true
  validates_numericality_of :min_trigger_amount, :greater_than => 0, :allow_blank => true
  validates_length_of :additional_details, :maximum => 254, :allow_nil => true, :allow_blank => true
  
  #before_save :get_billing_value


  def fixed_rate?
    self.billing_type.nil? || self.billing_type.blank? || self.billing_type.eql?("Fixed Rate") || self.billing_type.eql?("fixed_rate")
  end

  def toe_docs
    DocumentHome.all(:conditions => ["company_id = ? AND mapable_type = 'Matter' AND mapable_id = ? AND sub_type = 'Termcondition' AND sub_type_id = ?", self.matter.company_id, self.matter.id, self.id])
  end

  def get_billing_value
    if self.billing_type=='fixed_rate'
      self.billing_value=self.fixed_rate
    elsif self.billing_type=='retainer_rate'
      self.billing_value=self.retainer_rate
    elsif self.billing_type=='hourly_rate'
      self.billing_value=self.hourly_rate
    elsif self.billing_type=='retainer_rate'
      self.billing_value=self.not_to_exceed
    end
  end


  def save_with_doc(matter, data)
    # Name: Mandeep Singh
    # Date: Sep 9, 2010
    # Transaction purpose: Save document home along with termcondition object for matter.
    # Tables affected: matter_termconditions, document_homes, documents, assets.
    MatterTermcondition.transaction do
      if self.valid?
        matter_people_ids = matter.matter_peoples.collect { |e| e.id }
        doc_home = DocumentHome.new(:contact_ids => [matter.contact_id],:mapable_type=>'Matter', :mapable_id=>data[:mapable_id], :sub_type=>'Termcondition', :upload_stage=>1, :company_id=>data[:company_id],:created_by_user_id=>data[:created_by_user_id], :access_rights=>4,:matter_people_ids=> matter_people_ids)
        document = {:name=>data[:name],:bookmark=> data[:bookmark],:phase=>data[:phase],:privilege=>data[:privilege], :description=> data[:description], :author=>data[:author], :source=>data[:source],:file=>data[:file], :employee_user_id=> data[:employee_user_id], :created_by_user_id=>data[:created_by_user_id], :company_id=>data[:company_id]}
        if doc_home.save_with_document(document)
          self.save
          doc_home.update_attribute('sub_type_id',self.id)
          return true
        else
          doc_home.errors.each do |error|
            self.errors.add(error[0],error[1])
          end
          return false
        end
      else
        return false
      end
    end    
  end

  
end

# == Schema Information
#
# Table name: matter_termconditions
#
#  id                         :integer         not null, primary key
#  scope_of_work              :text
#  billing_rates_details      :text
#  terms_of_payment           :text
#  retainer_fee_detail        :text
#  client_obligations_impacts :text
#  disclaimers                :text
#  account_details            :text
#  billing_type               :string(255)
#  billing_value              :string(255)
#  matter_id                  :integer
#  created_at                 :datetime
#  updated_at                 :datetime
#  highlights                 :text
#  company_id                 :integer         not null
#  deleted_at                 :datetime
#  permanent_deleted_at       :datetime
#  created_by_user_id         :integer
#  updated_by_user_id         :integer
#  billing_by                 :string(64)
#  retainer_amount            :string(64)
#  not_to_exceed_amount       :string(64)
#  min_trigger_amount         :string(64)
#  fixed_rate_amount          :string(64)
#  additional_details         :string(255)
#


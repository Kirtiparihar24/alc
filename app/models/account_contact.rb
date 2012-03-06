class AccountContact < ActiveRecord::Base
  belongs_to :account
  belongs_to :contact
  validates_presence_of :account_id, :contact_id
  acts_as_paranoid
  after_save :update_respected_association
  after_destroy :update_respected_association

  def update_respected_association
    if @account = Account.find_with_deleted(self.account_id)
      @account.delta = true
      @account.save(false)
    end

    if @contact = Contact.find_with_deleted(self.contact_id)
      @contact.delta = true
      @contact.save(false)
    end
  end

end

# == Schema Information
#
# Table name: account_contacts
#
#  id                 :integer         not null, primary key
#  account_id         :integer
#  contact_id         :integer
#  deleted_at         :datetime
#  created_at         :datetime
#  updated_at         :datetime
#  priority           :integer
#  company_id         :integer
#  created_by_user_id :integer
#  updated_by_user_id :integer
#


# Author Milind
# For Account Contact duplication Related fixes.

namespace :account_contact_duplication_fixes do
  task :fix_account_contact_dup => :environment do
    acc_con = AccountContact.find(:all,
                                 :select => "contact_id, account_id, count(contact_id)",
                                 :group => "contact_id,account_id",
                                 :having => "count(contact_id) > 1",
                                 :order => "account_id, contact_id")
    acc_con.each do |acccon|
      #acc_con_id = AccountContact.find_by_contact_id_and_account_id(acccon['contact_id'], acccon['account_id'], :conditions => ["priority = 1"], :order => "updated_at desc")
      acc_con_id=nil;
      
      if(acc_con_id.nil?)
        acc_con_id = AccountContact.find_by_contact_id_and_account_id(acccon['contact_id'], acccon['account_id'], :conditions => ["priority = 1 or priority = 0"], :order => "updated_at desc")
      end

      if acc_con_id.nil?
        acc_con_id = AccountContact.find_by_contact_id_and_account_id(acccon['contact_id'], acccon['account_id'],:order => "updated_at desc")
      end
      deleted_rec = AccountContact.find(:all,:conditions => ["contact_id = #{acccon['contact_id']} and
                                               account_id = #{acccon['account_id']} and
                                               id not in (?)", acc_con_id.id]
                        )
      p "Original Record Id = #{acc_con_id.id}"
      deleted_rec.each do |del_rec|
        p "Deleteing duplicate Record = #{del_rec.id}"
         AccountContact.skip_callback(:update_respected_association) do
          del_rec.destroy!
         end
      end
    end
  end
end

namespace :financial_account do
  task :create_account_if_matter_contact_has_no_account => :environment do
    Matter.all.each  do |matter|
      user = User.find_by_sql("SELECT users.id FROM users INNER JOIN user_roles ON user_roles.user_id = users.id
                              INNER JOIN roles ON roles.id=user_roles.role_id where roles.name ='lawyer' AND users.company_id=#{matter.company_id} limit 1")
      if(matter.contact.accounts.size <= 0)
        Account.skip_callback(:send_mail_to_associates) do
          account =  Account.new({:company_id => matter.company_id, :name => matter.contact.full_name, :primary_contact_id => matter.contact.id,
              :employee_user_id =>matter.employee_user_id, :delta => false, :assigned_to_employee_user_id => user[0].id})
          account.valid?
          account.name = account.name + "#{rand(23)}" if(account.errors.on(:name))
          matter.contact.accounts << account
        end
      end
    end
  end

  task :company_lookup_values_for_financial_accunt => :environment do
    financial_account_types = ['Trust']
    approval_statuses = ['Not Needed','Approval','Pending','Approved']
    transaction_statuses = ['Cleared','Reconciled','Pending']
    Company.all.each do |company|
      financial_account_types.map{|x| company.financial_account_types << FinancialAccountType.new({:lvalue => x, :alvalue => x})}
      approval_statuses.map{|x| company.approval_statuses << ApprovalStatus.new({:lvalue => x, :alvalue => x})}
      transaction_statuses.map{|x| company.transaction_statuses << TransactionStatus.new({:lvalue => x, :alvalue => x})}
    end
  end
end
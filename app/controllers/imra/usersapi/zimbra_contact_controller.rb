class Zimbra::Usersapi::ZimbraContactController < ApplicationController

  #This Action saves the contact when it is dragged and dropped from contact address book to contact zimlet
  #it also sets the zimbra_contact_status=true if the contact is updated,which helps the callback to update it in our database
  skip_before_filter :verify_authenticity_token

  def create_contact
    begin
      params[:email_add] = "mkd@ddiplaw.com" if params[:email_add].eql?("mdickinson@mdick.liviaservices.com")
      user=User.find_by_email(params[:email_add])
      if user
        params[:contact].merge!(:company_id=>user.company_id,
          :contact_stage_id=>user.company.contact_stages.array_hash_value('lvalue','Lead','id'),
          :assigned_to_employee_user_id=>user.id,:employee_user_id=>user.id,:created_by_user_id=>user.id,:status_type=>user.company.lead_status_types.find_by_lvalue('New').id)
      end
      @contact=Contact.new(params[:contact])
      if (unique_email(@contact,params) && @contact.save_zimbra_contact(params))
        render :xml=>{:success=> "success"}
      else
        unless @same_contacts.present?
          render :xml=>@contact.errors
        else          
          render :xml=>{:dupcontact => @same_contacts}
        end
      end
    rescue Exception=>e
      render :xml=>{:error=>e}
    end
  end

  def getcontactstatus    
    @lookupvalues= current_company.contact_stage.find(:all,:select=>'id,alvalue')
    render :xml=>@lookupvalues.to_xml
  end

  def delete_contacts
    params[:ids]=params[:ids].split(',')
    params[:ids].each do |id|
      @contact=Contact.find_by_zimbra_contact_id(id)
      Contact.skip_callback(:update_into_zimbra) do
        @contact.deleted_at=Time.zone.now
        @contact.zimbra_contact_id=nil
        @contact.save(false)
      end
    end
    render :nothing=>true
  end

end


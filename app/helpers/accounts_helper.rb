module AccountsHelper
  def account_comment
    "User #{@current_user.full_name.try(:titleize)} created <Span color ='blue'> #{@contact.contact_stage.alvalue.titleize} #{@contact.full_name.try(:titleize)}</span>. Comment : #{params[:comment]}"
  end

  def check_available_contact
    if params[:contact]
      @contact = Contact.find(params[:contact][:id]) unless params[:contact][:id].blank?
    end
  end
  
end

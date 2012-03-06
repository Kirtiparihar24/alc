class HomeController < ApplicationController
  before_filter :authenticate_user!, :except => [ :toggle, :support,:get_sub_products, :get_ticket_sub_types ,:get_suggestions ]
  before_filter :get_helpdesk_data, :only=> [:support, :helpdesk]

#  require 'mail'
#   include LiviaMailConfig
  #----------------------------------------------------------------------------
  def index
    # The hook below can access controller's instance variables.
    if current_user
      if current_user.role?:livia_admin
        redirect_to companies_url
      elsif is_secretary_or_team_manager?
        redirect_to "/wfm/notes"
      elsif current_user.end_user
        redirect_to physical_clientservices_home_index_path
      elsif is_client
        redirect_to matter_clients_url
      elsif current_user.role?:lawfirm_admin
        redirect_to lawfirm_admins_url
        return
      end
   else
    flash[:error] = t(:flash_DB_error)
    redirect_to login_url
   end
  end

  def get_helpdesk_data      
    unless current_user      
      helpdeskdb =  ActiveRecord::Base.connection
       @current_product =  helpdeskdb.execute("select * from helpdesk.products where url ='#{request.url.split('/')[2] }' and key='#{APP_URLS[:livia_portal_key]}'")
       @products=@current_product
       @sub_products = helpdeskdb.execute("select id,name from helpdesk.product_items where product_id = #{@current_product[0]['id'].to_i}")
       @company=helpdeskdb.execute("select id,name from helpdesk.companies where id= #{@current_product[0]['company_id']}")
       @ticket_types = helpdeskdb.execute("select id,name from helpdesk.ticket_types where company_id = #{@company[0]['id'].to_i}  and is_internal is false order by name")
       @ticket_type= @ticket_types[0]
        @ticket_sub_types= helpdeskdb.execute("select id,name,description from helpdesk.ticket_sub_types where request_type_id = #{@ticket_types[0]['id'].to_i} and sales =FALSE order by id")
       @statuses ||= helpdeskdb.execute("select id,name from helpdesk.statuses where name='New'")
       @status = @statuses[0]     
    end
  rescue Exception =>e
  end
  
  def support
    unless request.post?
      render :layout => false
  end
    
  if request.post?
   unless current_user
      helpdeskdb =  ActiveRecord::Base.connection
       @email= params[:ticket][:email]
       @role = helpdeskdb.execute("select id from helpdesk.roles where name= 'Client User'")
       @created_for=   @created_by = helpdeskdb.execute("select * from helpdesk.users where email='#{@email}' or login like '#{@email}' ")
       if @created_by.ntuples > 0 && @created_by[0]['role_id'].eql?(@role[0]['id'])
         @company_client_user =  helpdeskdb.execute("select * from helpdesk.company_client_users where user_id= #{@created_for[0]['id'].to_i} ")
       end
   end
    ticket= params[:ticket].merge!({:request_sub_type_id=>  params[:ticket]['request_sub_type_id'] ? params[:ticket]['request_sub_type_id'] : nil,
                                     :product_item_ids=> params[:ticket]['sub_product_ids'] ? params[:ticket]['sub_product_ids'] * ',' : '',
                                     :created_by=>@created_by && @created_by.ntuples > 0  ? @created_by[0]['id'].to_i : nil ,:employee_user_id=>  (@created_for && @created_for.ntuples > 0  && !@created_for[0]['role_id'].eql?(@role[0]['id'])) ? @created_for[0]['id'] : nil ,
                                     :company_id=>@company[0]['id'].to_i,:product_id=>@current_product[0]['id'].to_i,:status_id => @status['id'], :company_client_user_id =>@company_client_user && @company_client_user.ntuples > 0  ? @company_client_user[0]['id'] : nil, :company_client_id=> @company_client_user.present? ? @company_client_user[0]['company_id'] : nil}) if params[:ticket]
                                      ticket.delete("email") if  (ticket[:employee_user_id].present? || ticket[:company_client_user_id].present?)
                                      ticket.delete("sub_product_ids");
     @ticket=HelpdeskTicket.new(ticket)
     responds_to_parent do
        if @ticket.save
          flash[:notice]= "Your ticket has been created. Your ticket number is #{@ticket.ticket_no }"
           render :update do |page|
              page << "tb_remove()"               
                page.redirect_to :back
                end
        else
           render :update do |page|               
               page.show 'ticket_errors'
              page.replace_html 'ticket_errors', "<div style='width: 390px;border: 2px solid red;padding: 7px;padding-bottom: 0;margin-bottom: 20px;background-color: #f0f0f0;'><h2 style='text-align: left;font-weight: bold;padding: 5px 5px 5px 15px;font-size: 12px;margin: -7px;margin-bottom: 0px;background-color: #c00;color: #fff;'> #{@ticket.errors.full_messages.count}  error prohibited this ticket from being saved</h2><ul style='padding-left:10px;' >" + @ticket.errors.full_messages.reverse.collect {|e| "<li  style='font-size: 10px;color: #000;list-style: square;'>" + e + "</li>"}.join(" ") + "</ul></div>"
            end         
        end   
      end
  end  
end

  def get_ticket_sub_types  
    helpdeskdb =  ActiveRecord::Base.connection
    @ticket_type = helpdeskdb.execute("select * from helpdesk.ticket_types where id= #{params[:request_type_id].to_i} order by name")
    @ticket_sub_types= helpdeskdb.execute("select * from helpdesk.ticket_sub_types where request_type_id= #{params[:request_type_id].to_i} and sales =FALSE order by id")    
    render :layout => false
  end

  def get_sub_products   
    helpdeskdb =  ActiveRecord::Base.connection
    @sub_products= helpdeskdb.execute("select * from helpdesk.product_items where product_id= #{params[:product_id].to_i}")   
    render :layout => false
  end

  def get_suggestions   
    helpdeskdb =  ActiveRecord::Base.connection
    @description= helpdeskdb.execute("select * from helpdesk.ticket_sub_types where id= #{params[:request_sub_type_id].to_i}")
    @suggestions= helpdeskdb.execute("select * from helpdesk.suggestions where request_sub_type_id= #{params[:request_sub_type_id].to_i}")
    render :layout => false
  end

  def helpdesk
    @helpdesk_user_id =helpdesk_logged_in_id
    @token = generate_token
    save_token(@token)
    session[:helpdesk] =true
    add_breadcrumb "Helpdesk", helpdesk_path
  end


private
  def save(upload)
    name =  sanitize_filename(upload.original_filename)
    directory = "#{RAILS_ROOT}/data"
    # create the file path
    path = File.join(directory, name)
    # write the file
    File.open(path, "wb") { |f| f.write(upload.read) }
  end

  def cleanup()
    FileUtils.rm_rf(File.join(RAILS_ROOT, 'data'))
  end

  def sanitize_filename(file_name)
    # get only the filename, not the whole path (from IE)
    just_filename = File.basename(file_name)
    # replace all none alphanumeric, underscore or perioids
    # with underscore
    just_filename.sub(/[^\w\.\-]/,'_')
  end

   def save_token(token)
     ActiveRecord::Base.connection.execute("UPDATE single_signon.user_apps SET auth_token = '#{token}', updated_at='#{Time.now}' WHERE product_user_id=#{helpdesk_logged_in_id} and product_id=(select id from helpdesk.products where key='#{APP_URLS[:livia_portal_key]}' limit 1)")
  end

end

class Wfm::DocumentHomesController < WfmApplicationController
  before_filter :authenticate_user!

  def new_document_home
    @mapable = params[:mapable_type].constantize.find(params[:mapable_id])
    @document_home=DocumentHome.new
    @document_homes = @mapable.document_homes
    @document= @document_home.documents.build
    @return_path = root_path
    render :layout => false
  end

  def create
    @mapable = params[:mapable_type].constantize.find(params[:mapable_id])
    data = params[:document_home]
    document = params[:document_home][:document_attributes]
    errors=[]
    if document
      document[:share_with_client] = true unless is_secretary_or_team_manager?
      @document_home = DocumentHome.new(data.merge!(:created_by_user_id => @current_user.id, :upload_stage => 1,:employee_user_id=>@current_user.id,
                 :mapable_type=>params[:mapable_type],:mapable_id=>params[:mapable_id],:company_id=>@mapable.company_id,:access_rights=>2))
      @document_home.folder_id = params[:folder_id]
      @document=@document_home.documents.build(document.merge(:company_id=>@mapable.company_id, :employee_user_id=> @current_user.id, :created_by_user_id=>@current_user.id ))
      @document_home.tag_list= params[:document_home][:tag_array].split(',')
      if @document_home.save
        flash[:notice] = "#{t(:text_document)} #{t(:flash_was_successful)} #{t(:text_uploaded)}"
      else
        if  params[:document_home][:document_attributes][:data].blank?
          errors <<  " Please select document to upload.  "
        end
        if  params[:document_home][:document_attributes][:name].blank?
          errors <<  "Name can't be blank. "
        end
      end
    else
      errors = 'No File selected for upload'
    end
    responds_to_parent do
      render :update do |page|
        if errors.blank?
          page << "jQuery('#document_success_div').html('#{flash[:notice]}');"
          page << "jQuery('#document_success_div').show();jQuery('#document_errors').hide();"
          page << "jQuery('#document_success_div').animate({opacity: 1.0}, 5000);jQuery('#document_success_div').fadeOut('slow');"
          page.replace_html 'documents', :partial => 'document_home',:locals => {:document_homes=>@mapable.document_homes}
          page << "jQuery('#document_home_document_attributes_data').val('');jQuery('#document_home_document_attributes_name').val('');jQuery('#document_home_tag_array').val('');jQuery('#document_home_document_attributes_data').focus();jQuery('#document_home_document_attributes_description').val('');"
        else
          errs = "<ul>" + errors.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
          page << "jQuery('#document_errors').html(\"#{errs}\");"
          page << "jQuery('#document_errors').show();"
        end
        page << "jQuery('#document_home_submit').show();"
        page << "jQuery('#disable_submit_tag').hide();"
        page << "jQuery('#cancel_btn').show();"
        page << "jQuery('#cancel_btn_hidden').hide();"
      end
    end
  end

  def update
    @document = Document.find(params[:id])
    render :update do |page|
      if @document.update_attributes(:share_with_client =>params[:share_with_client])
        page << "show_error_msg('doc_errors','Document updated successfully','message_success_div');"
      else
        page << "show_error_msg('doc_errors','There was error updating document. Please try again','message_error_div');"
      end
    end
  end
end

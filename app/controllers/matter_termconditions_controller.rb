# The Terms of Engagement entries in a matter are handled here.
# The new/edit/create/update all use the same view for their actions.
# The document attached is saved in the regular document_homes table.
# This controller preloads a matter, it is nested under that matter.
# So a matter id should be present to access any action of this controller.

class MatterTermconditionsController < ApplicationController  
  verify :method => :post , :only => [:create] , :redirect_to => {:action => :index}
  verify :method => :put , :only => [:update] , :redirect_to => {:action => :index}

  layout 'left_with_tabs'
  
  before_filter :get_base_data
  before_filter :authenticate_user!
  before_filter :get_matter
  before_filter :check_for_matter_acces, :only=>[:index]
  before_filter :check_access_to_matter
  before_filter :get_user, :except => [:supercede_or_replace_document,:supercede_or_replace_document_form,:toe_docs,:toe_doc_history,:toe_multi_upload]
  add_breadcrumb I18n.t(:text_matters), :matters_path

  def create_or_update
    authorize!(:supercede_or_replace_document,@user) unless @user.has_access?('Terms of Engagement')
    @termcondition = @matter.matter_termcondition
    if @termcondition      
      @termcondition.update_attributes(params[:matter_termcondition])
    else      
      @termcondition = @matter.build_matter_termcondition(params[:matter_termcondition])
      @termcondition.save
    end
    add_breadcrumb t(:text_terms_of_engagement), matter_matter_termconditions_path(@matter)
    render "create_or_update"
  end

  # For supercede of toe docs.
  # Supercede an old version of document with a newer one.
  def supercede_or_replace_document
    if params[:document_home].present?
      @doc_home = DocumentHome.scoped_by_company_id(@company.id).find(params[:doc_id])
      old_document=@doc_home.latest_doc
      params[:document_home][:employee_user_id]= get_employee_user_id
      params[:document_home][:company_id]= @company.id
      params[:document_home][:created_by_user_id]= current_user.id
      params[:document_home][:old_document]=old_document.id
      params[:document_home][:name]=old_document.name
      params[:document_home][:bookmark]=old_document.bookmark
      params[:document_home][:phase]=old_document.phase
      params[:document_home][:privilege]=old_document.privilege
      params[:document_home][:description]= old_document.description
      params[:document_home][:doc_source_id] = old_document.doc_source_id
      params[:document_home][:author]=old_document.author
      params[:document_home][:employee_user_id]=old_document.employee_user_id
      if  params[:document_home][:data].present? && @doc_home.superseed_document(params[:document_home], false)
        flash[:notice]="#{t(:text_document)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
      else
        flash[:error]="File size should be between is 1KB-50MB."
      end
    else
      flash[:error]="File size should be between is 1KB-50MB."
    end
    redirect_to :action => :index
  end

  # For supercede of toe docs form.
  def supercede_or_replace_document_form
    @termcondition = @matter.matter_termcondition
    @doc_home = DocumentHome.find(params[:document_home_id])
    @document_home = DocumentHome.new
    @document = @doc_home.latest_doc
    render :partial => "supercede_or_replace_document_form"
  end

  # Display ToE docs for client view.
  def toe_docs
    @toe_docs = @matter.matter_termcondition.toe_docs
    render :partial => "toe_docs"
  end

  # Display hiostory of a ToE doc for this ToE.
  def toe_doc_history
    @termcondition = @matter.matter_termcondition
    @toe_doc = DocumentHome.find(params[:document_home_id])
    render :partial => "toe_doc_history"
  end

  # For adding multiple toe docs form.
  def toe_multi_upload_form
    authorize!(:toe_multi_upload_form,@user) unless @user.has_access?('Terms of Engagement')
    @document_home = @matter.document_homes.new
    @document = @document_home.documents.build
    render :layout =>false
  end
  
  # For adding multiple toe docs.
  def toe_multi_upload
    @matter=Matter.find_by_id(params[:matter_id])
    params[:document_home][:document_attributes]={}
    params[:document_home][:document_attributes].merge!(:name=> params[:name],:data=>params[:file])
    # Name: Mandeep Singh
    # Date: Sep 9, 2010
    # Transaction purpose: If termcondition is not created for the matter create and save it.
    #  Add a document to existing or created termcondition object.
    # Tables affected: matter_termconditions, document_homes, documents, assets
    MatterTermcondition.transaction do
      @termcondition = @matter.matter_termcondition
      if @termcondition.nil?        
        @termcondition = @matter.build_matter_termcondition(:company_id => @matter.company_id)
        @termcondition.save # or raise @termcondition.errors.full_messages.inspect
      end
      if params[:document_home].present?
        document= params[:document_home][:document_attributes]
        params[:document_home].merge!(:employee_user_id=>params[:employee_user_id], :owner_user_id=>params[:employee_user_id],
          :created_by_user_id=>params[:current_user_id],:company_id=>@company.id,:access_rights=>3,
          :mapable_id=>@matter.id,:mapable_type=>'Matter',:upload_stage=>1,
          :sub_type=>'Termcondition',:sub_type_id => @termcondition.id)
        # Give permission to client.
        params[:document_home][:contact_ids]=[@matter.contact_id]
        # Set params for matter view access control.
        params[:document_home][:matter_people_ids]=[]
        params[:document_home][:repo_update] = false
        @document_home = @matter.document_homes.new(params[:document_home])
        @document = @document_home.documents.build(document.merge!(:created_by_user_id=>current_user.id,:company_id=>@company.id,:employee_user_id=>get_employee_user_id))
        responds_to_parent do
          render :update do |page|
            if params[:document_home][:document_attributes] && params[:document_home][:document_attributes][:data] && params[:document_home][:document_attributes][:data].size < Document::Max_multi_file_upload_size && params[:document_home][:document_attributes][:data].size !=0
             @document_home.save
            else
              @document_home.errors.add('File size ', 'is not in the correct range [1byte - 50 MB]')
            end
            if @document_home.errors
              errors = "<ul>" + @document_home.errors.full_messages.collect {|e| "<li>" + e + "</li>"}.join(" ") + "</ul>"
              page << "show_error_msg('matter_toe_error','#{errors}','message_error_div');"
              page << "jQuery('#loader').hide();"
              page << "enableAllSubmitButtons('matters');"
              page << "jQuery('#document_home_submit').attr('disabled', false);"              
              page << "jQuery('#document_home_submit').val('Upload');"
            end
          end
        end
      end
    end
  end

  # NOTE: Returns only one record.
  def index
    authorize!(:index,@user) unless @user.has_access?('Terms of Engagement')
    @termcondition = @matter.matter_termcondition || @matter.build_matter_termcondition
    @pagenumber=139
    add_breadcrumb t(:text_terms_of_engagement), matter_matter_termconditions_path(@matter)
  end

  def new
    authorize!(:new,@user) unless @user.has_access?('Terms of Engagement')
    @termcondition = @matter.build_matter_termcondition
    add_breadcrumb t(:text_terms_of_engagement), new_matter_matter_termcondition_path
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @termcondition }
    end
  end

  def edit
    authorize!(:new,@user) unless @user.has_access?('Terms of Engagement')
    @termcondition = @matter.matter_termcondition    
    add_breadcrumb t(:text_terms_of_engagement), edit_matter_matter_termcondition_path(@matter, @termcondition)
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @termcondition }
    end
  end

  def create
    authorize!(:create,@user) unless @user.has_access?('Terms of Engagement')
    data = params
    data[:matter_termcondition].merge!({
        :created_by_user_id => current_user.id,
        :company_id => @company.id,
        :matter_id=>data[:matter_id],
        :mapable_id=>data[:matter_id],
        :name=> @matter.name +  " #{t(:text_terms_of_engagement)}",
        :bookmark=>0,
        :phase=>nil,
        :privilege=>nil,
        :description=>nil,
        :author=>current_user.full_name,
        :source=> nil,
        :employee_user_id=>get_employee_user_id
      })
    @termcondition = @matter.build_matter_termcondition(data[:matter_termcondition])
    respond_to do |format|
      if @termcondition.save_with_doc(@matter, data[:matter_termcondition])
        flash[:notice] = "#{t(:text_terms_of_engagement)} " "#{t(:flash_was_successful)} " "#{t(:text_created)}"
        format.html {
          redirect_to(edit_matter_matter_termcondition_path(@matter, @termcondition))
        }
        format.xml  { render :xml => @termcondition, :status => :created, :location => @termcondition }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @termcondition.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    authorize!(:update,@user) unless @user.has_access?('Terms of Engagement')
    data = params
    data[:matter_termcondition].merge!({
        :updated_by_user_id => current_user.id,
        :company_id => @company.id,
        :matter_id=>data[:matter_id],
        :mapable_id=>data[:matter_id],
        :name=> @matter.name +  " #{t(:text_terms_of_engagement)}",
        :bookmark=>0,
        :phase=>nil,
        :privilege=>nil,
        :description=>nil,
        :author=>current_user.full_name,
        :source=> nil,
        :employee_user_id=>get_employee_user_id
      })
    @termcondition = @matter.matter_termcondition    
    respond_to do |format|      
      if  @termcondition.update_attributes(data[:matter_termcondition])
        flash[:notice] = "#{t(:text_terms_of_engagement)} " "#{t(:flash_was_successful)} " "#{t(:text_updated)}"
        format.html {
          redirect_to(edit_matter_matter_termcondition_path(@matter, @termcondition))
        }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @termcondition.errors, :status => :unprocessable_entity }
      end
    end
  end

  private
  def get_base_data
    @company ||= current_company
  end
  
end

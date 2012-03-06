module DocumentHomesHelper
  def document_accesible?(doc_home,emp_user_id= get_employee_user_id ,comp_id=get_company_id, matter=nil)
    case doc_home.access_rights
    when 1
      if doc_home.upload_stage == 2
        matt = matter || doc_home.mapable
        return client_document_accesible?(matt, doc_home,emp_user_id) || doc_home.user_ids.include?(emp_user_id) || doc_home.owner_user_id.eql?(emp_user_id)
      else
        return doc_home.user_ids.include?(emp_user_id) || doc_home.owner_user_id.eql?(emp_user_id)
      end
    when 2
      return doc_home.company_id == comp_id
    when 3
      return true if is_access_matter?
      matt = matter || doc_home.mapable
      m = matt.matter_peoples.find_by_employee_user_id(emp_user_id)
      return m.present?
    when 4
      matt = matter || doc_home.mapable
      if doc_home.upload_stage!=2
        return true if is_access_matter?
        access_controls=doc_home.document_access_controls.find(:all, :conditions => ["matter_people_id is not null"])
        access_controls.each do |mh|
          if mh.matter_people_id && ((matt.matter_peoples.find(mh.matter_people_id).employee_user_id) == emp_user_id || doc_home.owner_user_id==emp_user_id || emp_user_id==matter.employee_user_id)
            return true
          end
        end
      end
      if doc_home.upload_stage == 2
        return client_document_accesible?(matt, doc_home,emp_user_id)
      end
      return false
    else
      return false
    end
  end

  def doc_checked_access(doc_home, current_employee)
    case  doc_home.checked_in_by_employee_user_id
    when  current_employee
      # 'checked out by me'
      return '1'
    when nil
      # not checked out
      return '3'
    else
      # checked by some one else
      return '2'
    end
  end

  def get_uploaded_by_details(doc_home,doc)
    if doc.assigned_by
      if doc_home.documents[0].id==doc.id
        if doc.assigned_by.role?('client')
          return  '<b>Shared by Client: </b>' + doc.assigned_by.try(:full_name).try(:titleize) + '<b> [Converted by: </b>' +  doc.assignee.full_name.titleize + '<b>]</b>'
        else
          return doc.assignee.try(:full_name).try(:titleize)
        end
      else
        if doc.assigned_by.role?('client')
          return '<b>Shared By Client: </b>' +  doc.assigned_by.try(:full_name).try(:titleize) + "<b> [#{t(:label_superseed)} by: </b>" + doc.assignee.full_name.titleize + '<b>]</b>'
        else
          return doc.assignee.try(:full_name).try(:titleize)
        end
      end
    else
      return ''
    end
  end

  def check_client_instance(doc_home)
    flag=''
    # It seems that if upload_stage is 3 for a document_home then it can be 
    # considered as uploaded by client. We can avoid the following query which
    # is iterating over all documents for a document_home.
    if doc_home.upload_stage == 3
      flag = "<span class='icon_client_indicator fl mt3 vtip' title='Instance of client Document' > </span>"
    end
    return flag
  end

  def  get_acessible_documents(doc_homes)
    access_docs=[]
    doc_homes.each do |doc_home|
      if  document_accesible?(doc_home,get_employee_user_id, get_company_id, doc_home.mapable) &&  !doc_home.wip_document && doc_home.wip_doc.blank?
        access_docs << doc_home
      end
    end
    return access_docs
  end

  def clone_document_to_repository(data)
    temp_doc=DocumentHome.new(data)
    if temp_doc.validate_document(data)
      data[:mapable_type]='Company'
      data[:mapable_id]=data[:company_id]
      return data
    end

  end

  def create_clone_to_repository(document)
    repo_doc_home= self.children.new(:mapable_type=>'Company', :mapable_id=>self.company_id,:access_rights=>2, :upload_stage=>1)
  end

  def  update_repository_document(doc_home,data)

    doc_data={}
    doc_data[:name]= data[:document_home][:name]
    doc_data[:description] = data[:document_home][:description]
    begin
      self.transaction do
        if doc_home.access_rights == 2 && doc_home.children.first
          if data[:access_control]!='public'
            remove_document_from_repository(doc_home)
          else
            doc_home.children.first.latest_doc.update_attributes(doc_data) if doc_data[:name].present? && doc_home.repo_update
          end
        else
          if params[:access_control]=='public'
            doc_data[:created_by_user_id]=  current_user.id
            doc_data[:company_id]=doc_home.company_id
            doc_data[:author]= data[:document_home][:author]
            doc_data[:employee_user_id]=doc_home.employee_user_id
            doc_data[:doc_source_id]= data[:document_home][:doc_source_id]
            path = File.join(doc_home.latest_doc.url, doc_home.latest_doc.name)
            file=   File.open(path, "r")
            doc_data[:file]= file
            doc_data[:access_rights]=2
            doc_data[:upload_stage]=1
            doc_data[:mapable_type]='Company'
            doc_data[:mapable_id]=doc_home.company_id
            repo_doc_home= doc_home.children.new(doc_data)
            repo_document=  Document.new(:name=>doc_data[:name],:doc_source_id=>doc_data[:doc_source_id], :description=> doc_data[:description], :author=>doc_data[:author],:file=>doc_data[:file], :employee_user_id=> doc_data[:employee_user_id], :created_by_user_id=>doc_data[:created_by_user_id],:category_id=>current_company.document_categories.find_by_lvalue('Other').id, :company_id=>doc_home.company_id)
            repo_document.assets.build(:data=>doc_data[:file], :company_id=> doc_home.company_id)
            repo_doc_home.documents <<  repo_document
            repo_doc_home.save
          end
        end
      end
    rescue
      return false
    end
  end
   
  def remove_document_from_repository(doc_home)
    repo_doc= doc_home.children.first
    repo_doc.destroy if repo_doc
  end


  def show_check_uncheck_option(doc_home, check_level)
    if check_level=='1'
      #checked by me
      unless doc_home.wip_doc
        link_to(image_tag('/images/livia_portal/check.gif',{:alt =>"Click to check in", :title => "click to check in", :border => 0, :hspace => "2"}),check_uncheck_doc_document_home_path(:id=> doc_home.id,:matter_id=> doc_home.mapable_id,:lock=>'uncheck'))
      else
        link_to(image_tag('/images/livia_portal/icon_wip.png',{:alt =>"Click to check in ", :title => "Work in progress", :border => 0, :hspace => "2"}),wip_doc_action_document_home_path(:id=> doc_home.id,:matter_id=> doc_home.mapable_id, :height=>150, :width=>500), :class => "thickbox", :title => "Check in document [WIP ]", :name => "Check in document [WIP ]")
      end
    elsif check_level=='2'
      #checked_by_other
      unless doc_home.wip_doc?
        link_to(image_tag('/images/livia_portal/check-01.gif',{:alt =>"Checked out by: #{doc_home.checked_in_by.try(:full_name).try(:titleize)}", :title => "Checked out by: #{doc_home.checked_in_by.try(:full_name).try(:titleize)}",:matter_id=> doc_home.mapable_id, :border => 0, :hspace => "2"}),'#', :onclick=> "alert('Document already checked out by: #{doc_home.checked_in_by.try(:full_name).try(:titleize)}')")
      else
        link_to(image_tag('/images/livia_portal/icon_wip_02.png',{:alt =>"Checked out by: #{doc_home.checked_in_by.try(:full_name).try(:titleize)}", :title =>  "Checked out by: #{doc_home.checked_in_by.try(:full_name).try(:titleize)}",:matter_id=> doc_home.mapable_id, :border => 0, :hspace => "2"}),'#', :onclick=> "alert('Document already checked out by: #{doc_home.checked_in_by.try(:full_name).try(:titleize)}')")
      end
    elsif check_level=='3'
      #not checked
      link_to(image_tag('/images/livia_portal/check-02.gif',{:class=>"mt3",:alt =>"Click to check out", :title => "click to check out", :border => 0, :hspace => "2"}), check_uncheck_doc_document_home_path(:id=> doc_home.id, :matter_id => doc_home.mapable_id, :lock=>'check'), :confirm => "Note: No other user will be able to update this document until you check it in.!")
    end
  end


  def get_checkout_all_link(matter, current_employee)
    team_member = matter.get_team_member(current_employee)
    if matter.employee_user_id == current_employee || (team_member && team_member.can_checkin_docs?)
      link_to(image_tag('/images/livia_portal/check-in-doc.png',{:alt =>"Click to check out all",  :border => 0, :hspace => "2"})+"<span class='mr10 fr icon_name'>Check In Documents</span>", "#{check_out_all_document_homes_path()}?matter_id=#{matter.id}&height=150&width=550", :class => "mt1  mr5 thickbox", :name => "Check In Documents")
    end
  end
  
  def get_final_matter_doc(matter_document)
    wip_doc=matter_document.wip_document
    if  wip_doc && document_accesible?(wip_doc, get_employee_user_id , get_company_id , wip_doc.mapable)
      return true, wip_doc, matter_document
    else
      return false,matter_document, matter_document
    end
  end


  def get_accessible_people(doc_home)
    doc_home = doc_home.wip_parent || doc_home
    case doc_home.access_rights
    when 1
      return  doc_home.mapable.matter_peoples.find_all_by_employee_user_id(doc_home.user_ids[0]).collect
    when 2
      return  doc_home.mapable.matter_peoples.collect# {|e| e.id}
    when 3
      return  doc_home.mapable.matter_peoples.collect# {|e| e.id}
    when 4
      doc_home.matter_peoples
    else
      return []
    end
  end

  def get_wip(document)
    return  '[ WIP document ]'   if document.document_home.wip_parent.present?
  end

  def client_document_accesible?(matter, doc_home, emp_user_id)
    if(is_access_matter? && MatterPeople.is_part_of_matter_and_matter_people?(matter.id,emp_user_id))
      return true
    end
    team_member = matter.get_team_member(emp_user_id)
    if team_member
      if (matter.employee_user_id==emp_user_id || doc_home.employee_user_id==emp_user_id || doc_home.owner_user_id==emp_user_id)
        return true
      elsif doc_home.matter_task_ids.present?
        doc_home.matter_tasks.each do |task|
          if task.assigned_to_user_id==emp_user_id
            return true
          end
        end
      else
        team_member.can_view_client_docs?
      end
    else
      return false
    end
  end

  def return_folders_hash(id, title)
    return {"attr" => {"id" => "#{id}" } , "data" => {
        "title" => title.camelcase,
        "attr" => {"id" => "#{id}"}},
      "children" => [],
      "state" => "closed"}
  end

  def send_doc(path,params)
    email = params[:email][:to]
    subject=params[:email][:subject]
    begin
      user = current_user
      LiviaMailConfig::email_settings(user.company)
      mail_body = params[:email][:description]
      mail = Mail.new do
        from user.email
        to email
        subject subject
        part :content_type => "multipart/alternative"  do |prt|
          prt.html_part do
            content_type 'text/html; charset=UTF-8'
            body  "<pre>#{mail_body}</pre>"
          end
        end
      end
      mail.add_file "#{path}"
      mail.deliver
    rescue Timeout::Error => err
      logger.info "Timeout Error"
    rescue Exception => exec
      logger.info "Error while trying to send email"
      logger.info  exec.message
    end
  end

#to set the image for the extension type : Rashmi.N
  def get_file_extension(file)
    if(file.extension == 'png' || file.extension == 'jpg' || file.extension == 'gif' || file.extension == 'jpeg')
      "<div class='icon_image_file fl mr10'></div>"
    elsif(file.extension == 'pdf')
      "<div class='icon_pdf fl mr10'></div>"
    elsif(file.extension == 'xls' || file.extension == 'xlsx')
      "<div class='icon_xls fl mr10'></div>"
    elsif(file.extension == 'ppt')
      "<div class='icon_ppt fl mr10'></div>"
    elsif(file.extension == 'docx' || file.extension == 'doc')
      "<div class='icon_doc fl mr10'></div>"
    else
      "<div class='icon_file fl mr10'> &nbsp;</div>"
     end
  end
end

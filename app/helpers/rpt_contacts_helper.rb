module RptContactsHelper

  private

   # This method generate group_by clause
   # Group by has
   # "owner","assigned_to_user_id","User","name"
   # "stage","contact_stage_id","ContactStage","alvalue"
   # "account","account_id","Account","name"
   # "rating","rating","Contact","rating"
   # "source","source","CompanySource","alvalue"

  def group_current_contact(col,sources,stages,status_l)
    nonedata,data,column_widths,@conditions,@total_data,cstatus = [],[],{},{},{},''
    if params[:report][:summarize_by] == "contactstage"
      col.group_by(&:contact_stage_id).each do |label,gcol|
		    if stages[label].nil?
          gcol.each do |contact|
            #cstatus = get_contact_status_by_stage(contact, stages[label], status_l)
            nonedata << [contact.name,contact.accounts[0] ? contact.accounts[0].name : "",contact.phone,contact.email,sources[contact.source],contact.rating,contact.created_at ? contact.created_at.strftime('%m/%d/%y') : "",contact.get_assigned_to.to_s ]
          end
        else
          gcol.each do |contact|
            #cstatus = get_contact_status_by_stage(contact, stages[label], status_l)
            data << [contact.name,contact.accounts[0] ? contact.accounts[0].name : "",contact.phone,contact.email,sources[contact.source],contact.rating,contact.created_at ? contact.created_at.strftime('%m/%d/%y') : "",contact.get_assigned_to.to_s ]
          end
          @total_data[stages[label]] = data
          data = []
        end
      end
      @total_data[""] = nonedata unless nonedata.empty?
      column_widths =  { 0 => 100,                1 => 80,            2 => 80 ,       3 => 140 ,      4 => 60  ,       6 => 80 ,        7 => 60 ,        8 => 60 ,      9 => 0 } if params[:format] =="pdf"
      @table_headers = ["#{t(:label_contact)}","#{t(:label_Account)}",t(:label_phone),t(:label_email),t(:label_source),t(:label_rating),t(:text_created),t(:label_owner)]
    elsif params[:report][:summarize_by] == "owner"
      col.group_by(&:assigned_to_employee_user_id).each do |label, gcol|
        key = nil
        gcol.each do |contact|
          key =  contact.get_assigned_to.to_s unless key
          contactstage = contact.contact_stage.blank? ? nil : contact.contact_stage.lvalue
          #cstatus = get_contact_status_by_stage(contact, contactstage, status_l)
          data << [contact.name,contact.accounts[0] ? contact.accounts[0].name : "",contact.phone,contact.email,sources[contact.source],contact.rating,contact.created_at ? contact.created_at.strftime('%m/%d/%y') : "",stages[contact.contact_stage_id]]
        end
        @total_data[key.to_s] = data
        data = []
      end
      column_widths =     { 0 => 100,            1 => 80,             2 => 80 ,       3 => 140 ,      4 => 60  ,       6 => 80 ,        7 => 60 ,        8 => 60 ,     9 => 0 } if params[:format] =="pdf"
      @table_headers = ["#{t(:label_contact)}","#{t(:label_Account)}",t(:label_phone),t(:label_email),t(:label_source),t(:label_rating),t(:text_created),t(:label_stage)]
    elsif params[:report][:summarize_by] == "account"
      array = []
      col.group_by{|obj|
        unless obj.accounts[0]
          array << obj
          next
        end
        obj.accounts[0].id}.each_value do |gcol|
        key = nil
        gcol.each do |contact|
          key = contact.accounts[0] ? contact.accounts[0].name : "" unless key
          contactstage = contact.contact_stage.blank? ? nil : contact.contact_stage.lvalue
          #cstatus = get_contact_status_by_stage(contact, contactstage, status_l)
          data << [contact.name,contact.phone,contact.email,sources[contact.source], contact.rating,contact.created_at ? contact.created_at.strftime('%m/%d/%y') : "",contact.get_assigned_to.to_s,stages[contact.contact_stage_id]]
        end
        #end
        @total_data[key.to_s] = data
        data = []
      end
      data = []
      array.each do |contact|
        contactstage = contact.contact_stage.blank? ? nil : contact.contact_stage.lvalue
        #cstatus = get_contact_status_by_stage(contact, contactstage, status_l)
        data << [contact.name,contact.phone,contact.email,sources[contact.source], contact.rating,contact.created_at ? contact.created_at.strftime('%m/%d/%y') : "",contact.get_assigned_to.to_s,stages[contact.contact_stage_id]]
      end
      @total_data[""] = data unless data.blank?
      column_widths =     { 0 => 100,          1 => 80,        2 => 140 ,      3 => 60 ,        4 => 80  ,       6 => 60 ,        7 => 60 ,       8 => 80 ,      9 => 0 } if params[:format] =="pdf"
      @table_headers = ["#{t(:label_contact)}",t(:label_phone),t(:label_email),t(:label_source),t(:label_rating),t(:text_created),t(:label_owner),t(:label_stage)]
    elsif params[:report][:summarize_by] == "rating"
      @conditions[:rating] = true
      @rating = true
      col.group_by(&:rating).each do |label,gcol|
        gcol.each do |contact|
          contactstage = contact.contact_stage.blank? ? nil : contact.contact_stage.lvalue
          #cstatus = get_contact_status_by_stage(contact, contactstage, status_l)
          data << [contact.name,contact.accounts[0] ? contact.accounts[0].name : "",contact.phone,contact.email,sources[contact.source],contact.created_at ? contact.created_at.strftime('%m/%d/%y') : "",contact.get_assigned_to.to_s,stages[contact.contact_stage_id]]
        end
        @total_data[label] = data
        data = []
      end
      column_widths =     { 0 => 100,             1 => 80,            2 => 80 ,       3 => 140 ,      4 => 60  ,       6 => 60 ,        7 => 60 ,       8 => 110 ,      9 => 0 } if params[:format] =="pdf"
      @table_headers = ["#{t(:label_contact)}","#{t(:label_Account)}",t(:label_phone),t(:label_email),t(:label_source),t(:text_created),t(:label_owner),t(:label_stage)]
    elsif params[:report][:summarize_by] == "source"
      col.group_by(&:source).each do |label,gcol|
        if sources[label].to_s.empty?
          gcol.each do |contact|
            #cstatus = get_contact_status_by_stage(contact, sources[label], status_l)
            nonedata << [contact.name,contact.accounts[0] ? contact.accounts[0].name : "",contact.phone,contact.email,contact.rating,contact.created_at ? contact.created_at.strftime('%m/%d/%y') : "",contact.get_assigned_to.to_s,stages[contact.contact_stage_id]]
          end
        else
          gcol.each do |contact|
            #cstatus = get_contact_status_by_stage(contact, sources[label], status_l)
            data << [contact.name,contact.accounts[0] ? contact.accounts[0].name : "",contact.phone,contact.email,contact.rating,contact.created_at ? contact.created_at.strftime('%m/%d/%y') : "",contact.get_assigned_to.to_s,stages[contact.contact_stage_id]]
          end
          @total_data[sources[label].to_s] = data
          data = []
        end
      end
      @total_data[""] = nonedata unless nonedata.blank?
      column_widths =     { 0 => 100,             1 => 80,            2 => 80 , 3 => 140 , 4 => 80  , 6 => 40 , 7 => 40 , 8 => 110 , 9 => 0 } if params[:format] =="pdf"
      @table_headers = ["#{t(:label_contact)}","#{t(:label_Account)}","Phone",  "Email",   "Rating",  "Created","Owner",  "Stage"]
    end
    alignments = { 0 => :left, 1 => :left, 2 => :left , 3 => :left , 4 => :left , 5 => :center , 6 => :center ,7 => :left , 8 => :left } if params[:format] =="pdf"
    return column_widths,alignments
  end


  #Getting only Contacts which are linked with Account
  # This method generate group_by clause
   # Group by has
   # "account","account","account_contact","name"
   # "act_owner","assigned_to_user_id","User","name"

     def group_contact_account_rpt(col,sources,stages,status_l)
    data,@total_data,column_widths,@conditions  = [],{},{},{:col_length => 0}
    if params[:report][:summarize_by] == "account"
      col.group_by{|obj|
        next unless obj.accounts[0]
        obj.accounts[0].id}.each_value do |gcol|
        key = nil
        gcol.each do |contact|
          next unless contact.accounts[0]
          key = contact.accounts[0] ? contact.accounts[0].name : "" unless key
          #cstatus = get_contact_status_by_stage(contact, contact.contact_stage.lvalue, status_l)
          data << [contact.name,contact.phone,contact.email,sources[contact.source] ,contact.rating,contact.created_at ? contact.created_at.strftime('%m/%d/%y') : "",contact.get_assigned_to.to_s,stages[contact.contact_stage_id]]

        end
        
        next if data == []
        @total_data[key.to_s] = data
        @conditions[:col_length] += data.length
        data = []
      end
      
      column_widths = { 0 => 110, 1 => 80, 2 => 150 , 3 => 60  , 5 => 60 , 6 =>40 ,7 => 110 , 8 =>40} if params[:format] == "pdf"
      @table_headers = ["#{t(:label_contact)}",t(:label_phone),t(:label_email),t(:label_source),t(:label_rating),t(:text_created),t(:label_owner),t(:label_stage)]
    elsif params[:report][:summarize_by] == "act_owner"
      a_hash,i = {},0
      col.group_by(&:assigned_to_employee_user_id).each_value do |gcol|
        key = nil
        gcol.each do |contact|
          next unless account = contact.accounts[0] ? contact.accounts[0].name : nil
          key = contact.get_assigned_to.to_s unless key
          #cstatus = get_contact_status_by_stage(contact, contact.contact_stage.lvalue, status_l)
          if a_hash[account]
            a_hash[account] << [contact.name,contact.accounts[0] ? contact.accounts[0].name : "",contact.phone,contact.email,sources[contact.source],contact.rating,contact.created_at ? contact.created_at.strftime('%m/%d/%y') : "",stages[contact.contact_stage_id]]
          else
            a_hash[account] = [[contact.name,contact.accounts[0] ? contact.accounts[0].name : "",contact.phone,contact.email,sources[contact.source],contact.rating,contact.created_at ? contact.created_at.strftime('%m/%d/%y') : "",stages[contact.contact_stage_id]]]
          end
          i += 1
        end
        next if a_hash.empty?
        @conditions[key.to_s] = i
        @conditions[:col_length] += i
        @total_data[key.to_s] = a_hash
        a_hash,i = {},0
      end
##col.group_by(&:assigned_to_employee_user_id).each do |label, a_col|
##        clength = 0
##        a_col.each do |contact|
##          len = contact.accounts.length
###          raise len.inspect
##          next if  len == 0
##          clength += len
##          key = contact.get_assigned_to.to_s
##          contact.accounts.find(:all).each do |contact|
##            next unless contact
##            #sources[contact.source]=''
##            raise contact.rating.inspect
##            #,contact.phone,contact.email,sources[contact.source] ,stages[contact.contact_stage_id],contact.rating,contact.created_at ? contact.created_at.strftime('%m/%d/%y') : "",contact.get_assigned_to.to_s
##            #cstatus = get_account_status_by_stage(contact, contact.contact_stage.lvalue, status_l)
##            data << [contact.name,contact.phone,contact.email,sources[contact.source] ,stages[contact.contact_stage_id],contact.rating,contact.created_at ? contact.created_at.strftime('%m/%d/%y') : "",contact.get_assigned_to.to_s]
##          end
##          next if data.empty?
##          a_hash[account.name] = data
##          data = []
##        end #a_col
#
#        @total_data[key] = a_hash
#        @conditions[key] = clength
#        @conditions[:t_contacts] += clength
#        @conditions[:inner_keys] += a_col.length
#        a_hash = {}
#      end #col
      column_widths = { 0 => 100, 1 => 80, 2 => 80 , 3 => 150 , 4 => 80 , 6 =>40 ,7 => 100 , 8 =>40} if params[:format] == "pdf"
      @table_headers = ["#{t(:label_contact)}","#{t(:label_Account)}",t(:label_phone),t(:label_email),t(:label_source),t(:label_rating),t(:text_created),t(:label_stage)]
    end
    alignments = { 0 => :left, 1 => :left, 2 => :left , 3 => :left , 4 => :center  , 6 => :center ,7 => :center , 8 => :center } if params[:format] =="pdf"
    return column_widths,alignments
    
  end


  #This method is used to get the report name
  def set_report_name(r_type,hash)
    case r_type
    when 1
      if params['get_records'] == 'My'
        hash[:r_name] = "Current #{t(:label_contacts).titleize} for #{hash[:lawyer].titleize}"
      else
        hash[:r_name] = "Current #{t(:label_contacts).titleize} of  #{hash[:l_firm].titleize}"
      end
    when 2
      if params['get_records'] == 'My'
        hash[:r_name] += " for #{hash[:lawyer].titleize}"
      else
        hash[:r_name] += " for #{hash[:l_firm].titleize}"
      end
    else
      if params['get_records'] == 'My'
        hash[:r_name] = "#{t(:label_contacts).titleize} of #{hash[:lawyer].titleize} linked to #{t(:label_accounts).titleize}"
      else
        hash[:r_name] = "#{t(:label_contacts).titleize}  of #{hash[:l_firm].titleize} linked to #{t(:label_accounts).titleize}"
      end
      
    end
    
  end

  #This method is used to set conditions in search string based on user selection
  def set_contacts_conditions(checked)
    if checked == 'My'
      search = 'company_id=:company_id AND assigned_to_employee_user_id=:assign_to'
    else
      search = 'company_id=:company_id'
    end

    search
  end

  def get_contact_status_by_stage(contact, stage, status_l)
    cstatus = ''
    if stage == 'Lead'
      if (status_l[contact.status_type].nil? || status_l[contact.status_type].empty?)
        cstatus= LeadStatusType.find_by_lvalue_and_company_id('New', contact.company_id).alvalue
      else
      cstatus =  status_l[contact.status_type]
      end
   else
      if (status_l[contact.status_type].nil? || status_l[contact.status_type].empty?)
        cstatus= ProspectStatusType.find_by_lvalue_and_company_id('Active', contact.company_id).alvalue
      else
      cstatus = status_l[contact.status_type]
      end
    end
    cstatus
  end

  
end




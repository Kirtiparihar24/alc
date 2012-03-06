class DocumentManager
  #Use to find documnets from various modules according to selected criteria of advance search : Prtaik AJ
  def self.document_manager_search(params, company, current_user, date_range_for_doc, date_range_for_link, folders_array)
    sort = params[:dir].eql?("up")? "asc" : "desc"
    params[:col]="created_at" unless params[:col]
    name = params[:advance_search].eql?("true") ? params[:name].strip : params[:general_search].strip
    extension = params[:extension].strip
    description= params[:description].strip
    creator = params[:uploaded_by].strip
    tag = params[:tag].strip
    date = params[:date]
    document_type = params[:document_type].strip
    access_rights = params[:access_rights].split(',').collect!{|n| n.to_i}
    owner = params[:owner].strip.blank? ? '' : params[:owner].strip
    conditions=""
    mapable_ids = []
    mapable_ids_hash={}
    opportuniy_ids=[]
    if params[:mapable_type]
      mp_type = params[:mapable_type]
      params[:mapable_type] = mp_type.collect{|mp| mp.singularize.capitalize} unless params[:advance_search]=="true"
      #-----------------------Matter---------------------------
      if params[:mapable_type].include?("Matter") or ((mp_type[0] =~ /matters_(\d+)/) == 0 )
        get_matter_ids(params, mp_type, mapable_ids_hash, mapable_ids)
      end
      #--------------------------------------------------------
      #-----------------------Opportunity----------------------
      if params[:mapable_type].include?("Opportunity") or ((mp_type[0] =~ /opportunities_user_(\d+)/) == 0 ) #or params[:matter_opportunity]=='true'
        get_opportunity_ids(params,mp_type,mapable_ids_hash,mapable_ids)
      end
      #--------------------------------------------------------
      #-----------------------Time and Expense-----------------
      if params[:mapable_type].include?("Physical::Timeandexpenses::TimeEntry") or ((mp_type[0] =~ /time and expense(\D*)/) == 0 )
        get_tne_ids(params, mp_type, mapable_ids_hash)
      end
      #--------------------------------------------------------

      #-----------------------Campaigns------------------------
      if params[:mapable_type].include?("Campaign") or ((mp_type[0] =~ /campaigns_user_(\d+)/) == 0 )
        owner_id = mp_type[0].split("_").last.to_i unless params[:mapable_type].include?("Campaign")
        conditions = "name ILIKE '%#{params[:campaigns_name]}%'"
        conditions += " or name ILIKE '%#{params[:parent_campaign]}%'" unless params[:parent_campaign].blank?
        mapable_ids << Campaign.all(:conditions => conditions).collect{|a| a.id}
        mapable_ids_hash["campaign"]=mapable_ids.flatten
        owner = User.find(owner_id).full_name if owner_id
      end
      #--------------------------------------------------------

      #-----------------------Contacts-------------------------
      if params[:mapable_type].include?("Contact") or params[:mapable_type].include?("contacts")
        mapable_ids_hash["contact"]=[]
        mapable_ids << get_contacts(params[:contact_name])
        mapable_ids_hash["contact"]=mapable_ids.flatten
      end
      #--------------------------------------------------------
      #-----------------------Accounts-------------------------
      if params[:mapable_type].include?("Account")
        get_account_ids(params, mapable_ids_hash, mapable_ids)
      end
      #--------------------------------------------------------
      #-----------------------Workspace------------------------
      if params[:mapable_type].include?("Workspace") or ((mp_type[0] =~ /workspace_(\d+)/) == 0 )
        unless params[:mapable_type].include?("Workspace")
          document_home_ids,folder_ids = get_sub_folders_documents(mp_type[0])
        end
        mapable_ids_hash["user"]= [current_user.id]
      end
      #--------------------------------------------------------
      #-----------------------Repository-----------------------
      if params[:mapable_type].include?("Repository") or ((mp_type[0] =~ /repository_(\d+)/) == 0 )
        unless params[:mapable_type].include?("Repository")
          document_home_ids,folder_ids = get_sub_folders_documents(mp_type[0])
        end
        mapable_ids_hash["company"]= [company.id]
        link_condition_part = ((name == '' )? {} : {:link_name => name}).merge!(((tag == '')? {} : {:tag_name => tag})).merge!(((description == '')? {} : {:link_description=> description})).merge!(((creator == '')? {} : {:link_creator_name => creator}))
        link_with_part = (date == '2')? {:link_created_date => 1.weeks.ago.to_i..Time.zone.now.to_i} : ((date == '3')? {:link_created_date => 1.month.ago.to_i..Time.zone.now.to_i} : ((date == '4')? {:link_created_date => 1.year.ago.to_i..Time.zone.now.to_i} : ((date == '5')? date_range_for_link : {})))
        search_links = Link.current_company(company.id).search :conditions => link_condition_part, :with => link_with_part, :star => true, :limit => 10000  if params[:extension].blank?
      end
      #--------------------------------------------------------
      owner = User.find(owner_id).full_name if owner_id
    end
    date_part = (date == '2')? {:document_created_date => 1.weeks.ago.to_i..Time.zone.now.to_i} : ((date == '3')? {:document_created_date => 1.month.ago.to_i..Time.zone.now.to_i} : ((date == '4')? {:document_created_date => 1.year.ago.to_i..Time.zone.now.to_i} : ((date == '5')? date_range_for_doc : {})))
    with_part = (date_part.merge!({:document_access_rights => access_rights})).merge(((document_type == 'All')? {} : {:document_category_type=> document_type.to_i}).merge(((params[:client_docs].nil?) ? {} : {:document_upload_stage => 3})))
    condition_part = ((name == '' )? {} : {:document_name => name}).merge!(((owner == '' )? {} : {:document_owner => owner }).merge!(((extension == '')? {} : {:document_extension_type => extension}).merge!(((tag == '')? {} : {:doc_tag_name => tag})).merge!(((description == '')? {} : {:document_description=> description})).merge!(((creator == '')? {} : {:document_creator_name => creator})).merge((params[:privilege] =='All') ? {} : {:document_privilege => params[:privilege]}) ) )
    str=""
    folders_array.each_with_index do|n,index|
      (index == 0) ? str = n : str += " | " + n
    end
    condition_part.merge!(:document_mapable_type => str)
    documents = Document.current_company(company.id).search(:conditions => condition_part, :joins => :document_home, :select => "document_homes.*, documents.*", :with => with_part, :order => params[:col].try(:to_sym), :sort_mode => sort.try(:to_sym), :star => true, :limit => 10000)
    return mapable_ids_hash, document_home_ids,folder_ids, search_links, documents
  end

  #Return User object : Pratik AJ.
  def self.get_user(user_name)
    first_name,last_name = user_name.split(" ")
    User.all(:conditions => ["first_name ILIKE ? AND last_name ILIKE ?", "%#{first_name}%", "%#{last_name}%"]).collect(&:id)
  end

  #Return Contact object : Pratik AJ.
  def self.get_contacts(contact_name)
    contact_id =[]
    first_name, last_name = contact_name.split(" ") unless contact_name.blank?
    conditions = ["first_name ILIKE ? AND last_name ILIKE ?", "%#{first_name}%", "%#{last_name}%"]
    conditions[0] += " OR last_name IS NULL" if last_name.blank?
    contact_id = Contact.all(:conditions => conditions).collect(&:id)
    return contact_id
  end

  #Returns Sub Folder and document_home ids for selected folder for advance search : Prtaik AJ
  def self.get_sub_folders_documents(map_type)
    parent_id = map_type.split("_").last.to_i
    #    folder_ids = Folder.find_by_sql("SELECT * FROM connectby('folders', 'id', 'parent_id', #{parent_id}, 0) AS t(id int, parent_id int, node_level int)").collect{|folder| folder.id}
    folder_ids = Folder.find_by_sql("WITH RECURSIVE q AS(SELECT h FROM folders h
WHERE parent_id = 10017
UNION ALL SELECT hi FROM q JOIN folders hi ON hi.parent_id = (q.h).id)
SELECT (q.h).* FROM q;").collect{|folder| folder.id}
    dochome_ids = DocumentHome.all(:conditions => ["folder_id IN (?)",folder_ids]).collect{|dh| dh.id}
    return dochome_ids,folder_ids
  end

  #Returns Mapale ids for Matters according to selected criteria of advance search : Prtaik AJ
  def self.get_matter_ids(params,mp_type,mapable_ids_hash, mapable_ids=[])
    matter_id = mp_type[0].split("_").last.to_i unless params[:mapable_type].include?("Matter")
    matter_access= params[:matter_access]
    conditions ="name ILIKE '%#{params[:matter_name].try(:strip)}%'"
    unless params[:matter_lead_lawyer].blank?
      user_ids = get_user(params[:matter_lead_lawyer])
      uids= user_ids.blank? ? 0 : user_ids.flatten.join(",")
      conditions +=" and employee_user_id in (#{uids})"
    end
    conditions += " and id=#{matter_id}" if matter_id
    if !params[:matter_contact].blank? or !params[:matter_account].blank?
      contact_ids=[]
      contact_ids = get_contacts(params[:matter_contact]) unless params[:matter_contact].blank?
      unless params[:matter_account].blank?
        accounts = Account.all(:conditions => ["name ILIKE ?", "%#{params[:matter_account]}%"])
        contact_ids << accounts.collect{|account|
          account.contacts.collect{|contact| contact.id}
        }
      end
      #If contact_ids is blank then use 0 to avoid crash.
      # Its done on purpose to fetch the associated link between matter and contact. PratikAJ : 23-08-2011
      ids =  contact_ids.blank? ? 0 : contact_ids.flatten.join(",")
      conditions += " and contact_id in (#{ids})" unless params[:matter_contact].blank?
    end
    Matter.all(:conditions => conditions).each do|matter|
      mapable_ids << matter.id
      if params[:matter_sub_matter] == 'true'
        mapable_ids << matter.children.collect{|matter_child| matter_child.id}
      end
      # => : To be used for matter related opportunity document
      #          if params[:matter_opportunity]=='true'
      #            opportuniy_ids << matter.opportunity_id
      #          end
    end
    #       opportuniy_ids = opportuniy_ids.flatten
    mapable_ids_hash["matter"]= mapable_ids.flatten.uniq.compact
  end

  #Returns Mapale ids for Opportunity according to selected criteria of advance search : Prtaik AJ
  def self.get_opportunity_ids(params,mp_type,mapable_ids_hash,mapable_ids=[])
    owner_id = mp_type[0].split("_").last.to_i if ((mp_type[0] =~ /opportunities_user_(\d+)/) == 0 )
    conditions = "name ILIKE '%#{params[:opportunity_name].try(:strip)}%'"
    unless params[:opportunity_contact].blank?
      contact_ids = get_contacts(params[:opportunity_contact])
      opportuniy_ids = contact_ids.blank? ? 0 : contact_ids.flatten.join(",")
      conditions += " and contact_id in (#{opportuniy_ids})" unless params[:opportunity_contact].blank?
    end
    mapable_ids << Opportunity.all(:conditions => conditions).collect{|op| op.id}
    mapable_ids_hash["opportunity"] = mapable_ids.flatten
  end

  #Returns Mapale ids for TNE according to selected criteria of advance search : Prtaik AJ
  def self.get_tne_ids(params, mp_type, mapable_ids_hash)
    split_mapable = mp_type[0].split("_") unless params[:mapable_type].include?("Physical::Timeandexpenses::TimeEntry")
    user_ids = get_user(params[:tne_employee_name])
    uids= user_ids.blank? ? 0 : user_ids.flatten.join(",")
    conditions ="employee_user_id IN (#{uids})"
    if split_mapable
      if split_mapable.include?("matter")
        conditions +=" AND matter_id IS NOT NULL"
      elsif split_mapable.include?("non matter")
        conditions +=" AND contact_id IS NOT NULL AND matter_id IS NULL"
      elsif split_mapable.include?("internal")
        conditions +=" AND contact_id IS NULL and matter_id IS NULL"
      end
    end
    mapable_ids_hash["physical::timeandexpenses::timeentry"] = Physical::Timeandexpenses::TimeEntry.all(:conditions => conditions).collect{|tne| tne.id}.flatten
    mapable_ids_hash["physical::timeandexpenses::expenseentry"] = Physical::Timeandexpenses::ExpenseEntry.all(:conditions => conditions).collect{|tne| tne.id}.flatten
  end

  #Returns Mapale ids for accounts according to selected criteria of advance search : Prtaik AJ
  def self.get_account_ids(params, mapable_ids_hash, mapable_ids = [])
    mapable_ids_hash[:account] = []
    conditions = ["name ILIKE ?", "%#{params[:account_name].try(:strip)}%"]
    unless params[:accounts_primary_contact].blank?
      contact_ids = get_contacts(params[:accounts_primary_contact])
      ids = contact_ids.blank? ? 0 : contact_ids.flatten.join(",")
      conditions[0] += " AND primary_contact_id IN (#{ids})"
    end
    mapable_ids << Account.all(:conditions => conditions).collect{|a| a.id}
    mapable_ids_hash["account"] = mapable_ids.flatten
  end
end

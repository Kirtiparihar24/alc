class DocumentHome < ActiveRecord::Base
  #  include DocumentHomesHelper
  DIR_SORT_ORDER =  {"up" => " asc" ,"down" => " desc"}
  acts_as_paranoid
  belongs_to  :user, :foreign_key =>'created_by_user_id', :class_name => 'User'
  belongs_to  :employee, :foreign_key =>'employee_user_id', :class_name => 'User'
  belongs_to  :owner, :foreign_key =>'owner_user_id', :class_name => 'User'
  has_many :documents, :dependent => :destroy, :validate => :true, :with_deleted => true
  has_many :document_access_controls
  has_many :matter_peoples, :through => :document_access_controls, :validate=>:false
  has_many :users, :through => :document_access_controls, :foreign_key =>'employee_user_id', :validate => false
  has_many :contacts, :through => :document_access_controls,:validate=> false  
  has_one  :wip_document, :class_name => 'DocumentHome', :foreign_key=>'wip_doc'
  belongs_to :wip_parent, :class_name=> 'DocumentHome', :foreign_key=> 'wip_doc'
  belongs_to  :checked_in_by, :class_name => "User", :foreign_key => :checked_in_by_employee_user_id
  belongs_to :company
  belongs_to :folder
  belongs_to :comment
  acts_as_taggable
  belongs_to :mapable, :polymorphic=>true
  default_scope :order => 'document_homes.created_at DESC'
  before_save :repository_change 
  before_save :set_extension
  after_save :update_latest_doc
  has_and_belongs_to_many :matter_issues
  attr_reader :ACCESS_RIGHT
  has_and_belongs_to_many :matter_facts
  has_and_belongs_to_many :matter_risks
  has_and_belongs_to_many :matter_tasks
  has_and_belongs_to_many :matter_researches

  # Return only those document_homes for which the asscociated document has given category.
  named_scope :has_category, lambda {|kat|
    if kat.to_i > 0
      {:joins => [:documents], :conditions => ["documents.doc_type_id = #{kat}"]}   
    end
  }
  named_scope :repository_root_documents, {:conditions => ['folder_id is null']}
   
  named_scope :uploaded_by_lawyer, lambda {|euid,folder_id| 
    conditions ="sub_type IS NULL AND wip_doc IS NULL AND upload_stage != 2 AND ((access_rights = 1 AND owner_user_id = #{euid}) OR access_rights != 1)"
    if folder_id.blank?
      conditions+=" AND folder_id is null"
    else
      conditions+=" AND folder_id=#{folder_id}"
    end
    {:conditions =>conditions} }

  named_scope :uploaded_by_client, lambda {|euid| {:conditions =>
        ["sub_type IS NULL AND wip_doc IS NULL AND upload_stage = 2"]} }

  named_scope :private_to_lawyer, lambda {|euid| {:conditions =>
        ["owner_user_id = #{euid}"]} }

  attr_accessor  :document_attributes, :file, :name, :doc_source_id,:phase_id,
    :bookmark,:description, :author, :brief,:source,:privilege, :old_document,
    :superseed,:client_access,:category_id, :sub_category_id,:url,
    :created_by_employee_user_id, :tag_array, :repo_doc_id, :from_others
  acts_as_tree
  
  ACCESS_RIGHT = {1 => "Private", 2 => "Public",  3=> 'Matter View', 4=>'Selective'}
  
  ## The following method return the JSon result need by Jstree to build tree
  def self.tree_node(mapable_type, company, user, employee_user_id, is_secretary, folders_tree, perpage = 25, params=nil, folders_list=nil, sort='asc', col='document_homes.created_at')
    if col == "owner"
      order = "users.first_name #{sort}, users.last_name #{sort}"
      column = "owner_user_id"
    elsif col == "created_by"
      order = "users.first_name #{sort}, users.last_name #{sort}"
      column = "employee_user_id"
    else
      order = "#{col} #{sort}"
      column = "employee_user_id"
    end
    if params[:secondary_sort]
      secondary_sort = params[:secondary_sort_direction].eql?("up")? "asc" : "desc"
      if params[:secondary_sort]=="owner"
        order += ", users.first_name #{secondary_sort}, users.last_name #{secondary_sort}"
      elsif params[:secondary_sort]=="created_by"
        order += ", users.first_name #{secondary_sort}, users.last_name #{secondary_sort}"
      else
        order += ", #{params[:secondary_sort]} #{secondary_sort}"
      end
    end
    total = 0
    perpage = perpage.to_i
    params[:page] ||=1
    conditions = "document_homes.company_id = #{company.id}"
    result_folders, files, folders = [], [], []
    related_to = mapable_type
    offset =  calculate_offset(0,perpage,params[:page])
    docs=[]
    common_sql = "select document_homes.*, documents.* from documents left outer join document_homes
on document_homes.id = documents.document_home_id left outer join users on document_homes.#{column} = users.id
where documents.id in (select  max(docs.id) from documents docs inner join document_homes dh on dh.id = docs.document_home_id
group by dh.id) and document_homes.company_id = '#{company.id}' "
    if mapable_type =~ /root/
      folders = folders_list
      result_folders =folders_list if folders_tree
    elsif mapable_type =~ /repository/
      repo_sql = common_sql + " and document_homes.mapable_type ='Company' and document_homes.mapable_id ='#{company.id}' and document_homes.deleted_at is NULL "
      if mapable_type =~ /repository_(\d+)/
        parent_id = mapable_type.split("_").last.to_i
        folder = company.folders.find(parent_id)
        folders = []
        company_folders = folder.children
        folders = company_folders.paginate(:per_page => perpage, :page => params[:page])
        files = []
        total += company_folders.count
        total += folder.files.count
        total += folder.links.count
        tot_page = (total.to_f / perpage.to_f).ceil
        params[:page] = tot_page if (tot_page != 0 && tot_page < params[:page].to_i)
        # Paginate the files for remaining records (if there were fewer folders than 25)
        if folders.size < perpage
          offset =  calculate_offset(folders.total_entries, perpage, params[:page])
          repo_sql += " and document_homes.folder_id = #{folder.id} order by #{order} LIMIT #{set_limit(offset,perpage)} OFFSET #{round_to_zero(offset)}"
          docs = Document.find_by_sql(repo_sql)
          files = docs
        end
        if (folders.size + files.size) < perpage
          total_document_homes = perpage*(params[:page].to_i-1)+files.size
          offset =  calculate_offset(total_document_homes,perpage,params[:page])
          # Paginate the links for remaning records (if there were fewer than 25 folders & files)
          links = folder.links.all(:offset => round_to_zero(offset), :limit => set_limit(offset, perpage))
          files += links
        end
      else
        company_folders = company.folders.all(:conditions=> ['parent_id is null'])
        folders = company_folders.paginate(:per_page => perpage, :page => params[:page])
        total += company_folders.count
        total += company.repository_documents.repository_root_documents.count
        total += company.links.root_links.count
        tot_page = (total.to_f / perpage.to_f).ceil
        params[:page] = tot_page if (tot_page != 0 && tot_page < params[:page].to_i)
        if folders.size < perpage
          offset =  calculate_offset(folders.total_entries, perpage, params[:page])
          repo_sql += " and document_homes.folder_id is NULL order by #{order} LIMIT #{set_limit(offset,perpage)} OFFSET #{round_to_zero(offset)}"
          docs = Document.find_by_sql(repo_sql)
          files = docs
        end
        if (folders.size + files.size) < perpage
          total_document_homes = perpage*(params[:page].to_i-1)+files.size
          offset =  calculate_offset(total_document_homes,perpage,params[:page])
          # Paginate the links for remaning records (if there were fewer than 25 folders & files)
          links = company.links.all(:conditions => ['folder_id IS NULL'], :offset => round_to_zero(offset), :limit => set_limit(offset, perpage))
          files += links
        end
      end
    elsif mapable_type =~ /workspace/
      workspace_sql = common_sql + " and document_homes.mapable_type ='User' and document_homes.mapable_id ='#{employee_user_id}' and document_homes.deleted_at is NULL "
      if mapable_type =~ /workspace_(\d+)/
        workspace_id = mapable_type.split("_").last.to_i
        folder = Folder.find(workspace_id)
        flconditions = []
        flconditions = ["livian_access = ?", true] if is_secretary
        user_folders = folder.children.scoped_by_employee_user_id(user.id).all(:conditions => flconditions)
        total = user_folders.count
        total += folder.files.count unless folders_tree
        tot_page = (total.to_f / perpage.to_f).ceil
        params[:page] = tot_page if (tot_page != 0 && tot_page < params[:page].to_i)
        folders = user_folders.paginate(:per_page => perpage, :page => params[:page])
        if folders.size < perpage
          offset =  calculate_offset(folders.total_entries, perpage, params[:page])
          workspace_sql +="and document_homes.folder_id = '#{folder.id}' order by #{order} LIMIT #{set_limit(offset,perpage)} OFFSET #{round_to_zero(offset)}"
          files = Document.find_by_sql(workspace_sql)
        end
      else
        flconditions = "parent_id IS NULL "
        flconditions += "AND livian_access = true" if is_secretary
        user_folders = user.folders.all(:conditions => flconditions)
        total = user_folders.count
        total += user.document_homes.count(:conditions=> ['folder_id is null']) unless folders_tree
        tot_page = (total.to_f / perpage.to_f).ceil
        params[:page] = tot_page if (tot_page != 0 && tot_page < params[:page].to_i)
        folders = user_folders.paginate(:per_page => perpage, :page => params[:page])
        if folders.size < perpage
          offset =  calculate_offset(folders.total_entries, perpage, params[:page])
          workspace_sql += " and document_homes.folder_id is NULL order by #{order}  LIMIT #{set_limit(offset,perpage)} OFFSET #{round_to_zero(offset)}"
          files = Document.find_by_sql(workspace_sql)
        end
      end
    elsif mapable_type =~ /recycle_bin/
      rec_sql = common_sql + " and document_homes.permanent_deleted_at is null"
      if mapable_type =~ /recycle_bin_(\d+)/
        folder_id = mapable_type.split("_").last.to_i
        folder = Folder.find_only_deleted(folder_id)
        if folder.mapable_type=="User" && params[:page].to_i < 2
          if is_secretary
            folders = folder.children.scoped_by_employee_user_id(employee_user_id).find_only_deleted(:all, :conditions => ["livian_access = ? AND permanent_deleted_at IS NULL", true])
          else
            folders = folder.children.find_only_deleted(:all, :conditions => ["permanent_deleted_at IS NULL"])
          end
        elsif folder.mapable_type=="Company"
          folders = folder.children.find_only_deleted(:all)
        end
        rec_sql += " and document_homes.folder_id =#{folder.id} and document_homes.deleted_at is NOT NULL order by #{order} LIMIT #{set_limit(offset,perpage)} OFFSET #{round_to_zero(offset)}"
        files = Document.find_by_sql(rec_sql)
        if files.size < perpage
          total_document_homes = perpage*(params[:page].to_i-1)+files.size
          offset =  calculate_offset(total_document_homes,perpage,params[:page])
          # Paginate the links for remaning records (if there were fewer than 25 folders & files)
          files += folder.links.find_only_deleted(:all,:conditions => ["folder_id = ?",folder.id],:include=>[:created_by])
        end
      else
        folders, ids, folders_conditions= [], [], ""
        ids_conditions = "permanent_deleted_at is null"
        #------Finds Repository Deleted Folders------------------------------
        repo_folder_ids = company.folders.find_only_deleted(:all, :select=>"id", :conditions=> ids_conditions).collect(&:id)
        folders_conditions = " permanent_deleted_at is null and (parent_id is null or parent_id not in (#{repo_folder_ids.blank? ? -1 : repo_folder_ids.join(',')}))"
        folders = company.folders.find_only_deleted(:all, :conditions=> folders_conditions) if params[:page].to_i < 2
        #--------------------------------------------------------------------
        condition_link = 'permanent_deleted_at is null'
        condition_link += " and (links.folder_id is null or links.folder_id not in (#{repo_folder_ids}))" if repo_folder_ids.size > 0
        #------Finds Workspace Deleted Folders------------------------------
        if is_secretary
          ids_conditions += " and livian_access=true"
          folders_conditions ="livian_access=true and"
        else
          folders_conditions =""
        end
        user_folder_ids = user.folders.find_only_deleted(:all, :select=>"id", :conditions=> ids_conditions).collect(&:id)
        folders_conditions +=" permanent_deleted_at is null and (parent_id is null or parent_id not in (#{user_folder_ids.blank? ? -1 : user_folder_ids.join(',')}))"
        folders += user.folders.find_only_deleted(:all,:conditions=>folders_conditions) if params[:page].to_i < 2
        #--------------------------------------------------------------------
        ids = (user_folder_ids + repo_folder_ids).compact
        if ids.size > 0
          condition_doc = "and (document_homes.folder_id is null or document_homes.folder_id not in (#{ids}))"
        end
        #------Finds Repository / Workspace Deleted Documents----------------
        rec_sql += " #{condition_doc} and ((document_homes.mapable_type ='Company' and document_homes.mapable_id ='#{company.id}') OR (document_homes.mapable_type ='User' and document_homes.mapable_id ='#{employee_user_id}')) and document_homes.deleted_at is NOT NULL  order by #{order} "
        rec = Document.find_by_sql(rec_sql)
        files = rec.paginate(:per_page => perpage, :page => params[:page])
        total = rec.count
        #--------------------------------------------------------------------
        if files.size < perpage
          total_document_homes = perpage*(params[:page].to_i-1)+files.size
          offset =  calculate_offset(total_document_homes,perpage,params[:page])
          # Paginate the links for remaning records (if there were fewer than 25 folders & files)
          files += company.links.find_only_deleted(:all, :conditions=> condition_link, :include=>[:created_by], :offset => round_to_zero(offset), :limit => set_limit(offset, perpage))
        end
        total += company.links.count(:conditions=> condition_link, :include=>[:created_by])
      end
    elsif mapable_type =~ /time and expense/
      if mapable_type =="time and expense"
        types =  ["matter","non matter", "internal"]
        types.each do |type|
          mapable = "#{mapable_type}_#{type}"
          folders << [type.capitalize, mapable]
          result_folders << return_folders_hash(mapable, "#{type}") if folders_tree
        end
      else
        split_mapable = mapable_type.split("_")
        type_array = ["Physical::Timeandexpenses::TimeEntry","Physical::Timeandexpenses::ExpenseEntry"]
        type_array.each do |type|
          table_name = ((type == "Physical::Timeandexpenses::TimeEntry") ? "time_entries" : "expense_entries")
          conditions = "document_homes.company_id = #{company.id}"
          conditions += " and mapable_type = '#{type}'"
          if split_mapable.include?("matter")
            conditions += " and #{table_name}.matter_id IS NOT NULL"
          elsif split_mapable.include?("non matter")
            conditions += " and #{table_name}.contact_id is not null and #{table_name}.matter_id is null"
          elsif split_mapable.include?("internal")
            conditions += " and #{table_name}.contact_id is null AND #{table_name}.matter_id is null"
          end
          docs += Document.find_by_sql("select document_homes.*,documents.* from documents left outer join document_homes
on document_homes.id = documents.document_home_id
inner join users on document_homes.#{column} = users.id
inner join #{table_name} on document_homes.mapable_id = #{table_name}.id
where  documents.id in (select  max(docs.id)  from documents docs inner join document_homes dh on dh.id = docs.document_home_id
group by dh.id) and document_homes.deleted_at is NULL and #{conditions} order by #{order} ")
          files = docs.paginate(:per_page => perpage, :page => params[:page])
          total += docs.count
        end
      end
    elsif mapable_type =~ /matters/
      matters = Matter.unexpired_team_matters(user.id, company.id, Time.zone.now.to_date).uniq
      matter_ids = matters.blank? ? [] : matters.collect{|matter| matter.id}
      split_mapable = mapable_type.split("_")
      matter_id = (split_mapable.length > 1) ? split_mapable[1].to_i : nil
      if matter_id.blank?
        conditions += " and mapable_type = '#{mapable_type.singularize.capitalize}'"
        conditions += " and mapable_id in (#{matter_ids.join(',')})" if matter_ids.length > 0
      else
        conditions += " and mapable_type = '#{split_mapable[0].singularize.capitalize}' and mapable_id = #{matter_id}"
      end
      conditions += " and  upload_stage !=2 and ((access_rights = 1 and owner_user_id = #{employee_user_id}) or access_rights != 1)"
      if matter_id.blank?
        docs = DocumentHome.all(:conditions => conditions)
        accessible_docs = docs.find_all{|e| e.upload_stage != 2 && ((e.access_rights == 1 && e.owner_user_id == employee_user_id) || e.access_rights != 1)}
        unless accessible_docs.empty?
          accessible_docs.group_by(&:mapable_id).each do |matterid, items|
            matter_name = Matter.find(matterid).name
            mapable = "matters_#{matterid}"
            folders << [matter_name, mapable]
            result_folders << return_folders_hash(mapable, matter_name) if folders_tree
          end
        end
      else
        matter_sql = common_sql + " and #{conditions} and document_homes.deleted_at is NULL order by #{order} "        
        accessible_docs = Document.find_by_sql(matter_sql)
        total = accessible_docs.count
        files = accessible_docs.paginate(:per_page => perpage, :page => params[:page])
      end
    else
      # Documents Related To Contacts, Accounts, Opportunity And Campaign : Pratik AJ.
      split_mapable = mapable_type.split("_")
      userid = (split_mapable.include?("user")) ? split_mapable[2].to_i : nil
      if userid.blank?
        conditions += " and mapable_type= '#{mapable_type.singularize.capitalize}'"
        crm_sql = common_sql + " and #{conditions} and document_homes.deleted_at is NULL order by #{order}"
        docs = Document.find_by_sql(crm_sql)        
        if mapable_type == "opportunities" or mapable_type == "campaigns"
          unless docs.empty?
            docs.group_by(&:owner_user_id).each do |usrid, items|
              user_name = User.find(usrid).full_name
              mapable = "#{mapable_type}_user_#{usrid}"
              folders << [user_name, mapable]
              result_folders << return_folders_hash(mapable, user_name) if folders_tree
            end
          end
        else
          files = docs.paginate(:per_page => perpage, :page => params[:page])
        end
      else
        conditions += " and mapable_type= '#{split_mapable[0].singularize.capitalize}' and owner_user_id = #{userid}"
        crm_sql = common_sql + " and #{conditions} and document_homes.deleted_at is NULL order by #{order}"
        docs = Document.find_by_sql(crm_sql)
        files = docs.paginate(:per_page => perpage, :page => params[:page])
      end
      total = docs.count unless folders_tree
    end
    records = WillPaginate::Collection.new(params[:page] || 1, perpage, total)
    rep = files.to_a
    rep += folders.to_a if mapable_type =~ /repository/ || mapable_type =~ /workspace/
    records.replace(rep)
    if folders_tree
      if mapable_type =~ /workspace/ or mapable_type =~ /repository/ or mapable_type =~ /recycle_bin/
        unless folders.empty?
          folders.each do |folder|
            result_folders << return_folders_hash("#{mapable_type}_#{folder.id}", "#{folder.name}")
          end
        end
      end
      result_folders
    else
      [folders, files, records, related_to]
    end
  end

  def self.return_folders_hash(id, title)
    {"attr" => {"id" => "#{id}" } , "data" => {
        "title" => title.camelcase,
        "attr" => {"id" => "#{id}"}},
      "children" => [],
      "state" => "closed"}
  end

  def update_latest_doc
    self.latest_doc.save(false) if self.latest_doc
  end

  def self.create_new_document(data)
    doc_home = DocumentHome.new(data)
    data['name']= data['mapable_type'] + ' Document' unless data['name']
    data['bookmark']=0
    data['phase_id']=nil
    data['source']='Other'
    if doc_home.save_with_document(data)
      true
    else
      false
    end
  end

  def save_with_document(doc_data)
    begin
      DocumentHome.transaction do
        if doc_data[:name].present?
          document =  Document.new(:name=>doc_data[:name],:bookmark=> doc_data[:bookmark],:phase_id=>doc_data[:phase_id],:privilege=>doc_data[:privilege], :description=> doc_data[:description], :author=>doc_data[:author], :doc_source_id=>doc_data[:doc_source_id],:source=>doc_data[:source],:file=>doc_data[:file], :employee_user_id=> doc_data[:employee_user_id], :created_by_user_id=>doc_data[:created_by_user_id], :company_id=>doc_data[:company_id],:category_id=>doc_data[:category_id],:sub_category_id=>doc_data[:sub_category_id], :data=>doc_data[:file])
        else
          document =  Document.new(:name=>doc_data[:file].original_filename,:bookmark=> doc_data[:bookmark],:phase_id=>doc_data[:phase_id],:privilege=>doc_data[:privilege], :description=> doc_data[:description], :author=>doc_data[:author], :doc_source_id=>doc_data[:doc_source_id],:source=>doc_data[:source],:file=>doc_data[:file], :employee_user_id=> doc_data[:employee_user_id], :created_by_user_id=>doc_data[:created_by_user_id], :company_id=>doc_data[:company_id],:category_id=>doc_data[:category_id],:sub_category_id=>doc_data[:sub_category_id], :data=>doc_data[:file])
        end      
        self.documents << document
        if  document.valid? && self.save
          if self.mapable_type=='Matter' && self.access_rights==2
            repo_doc_home= self.children.new(clone_document_to_repository(doc_data))
            repo_document=  Document.new(:name=>doc_data[:file].original_filename,:bookmark=> doc_data[:bookmark],:phase_id=>doc_data[:phase_id],:privilege=>doc_data[:privilege], :description=> doc_data[:description], :author=>doc_data[:author], :source=>doc_data[:source],:file=>doc_data[:file], :employee_user_id=> doc_data[:employee_user_id], :created_by_user_id=>doc_data[:created_by_user_id], :company_id=>doc_data[:company_id], :category_id=>self.company.document_categories.find_by_lvalue('Other').id)
            repo_document.assets.build(:data=>doc_data[:file], :company_id=>doc_data[:company_id])
            repo_doc_home.documents <<  repo_document
            repo_doc_home.save
          end
          true
        else
          document.errors.each do |error|
            self.errors.add(' ', error[1])
          end
          false
        end
      end
    end
  end

  def repository_change
    if mapable_type=='Matter'
      if new_record?
        if access_rights==2
          repo_doc_home = children.build(:mapable_type=>'Company', :mapable_id=> company_id, :upload_stage => 1,:access_rights => 2, :company_id => self.company_id, :parent_id => id, :created_by_user_id => self.employee_user_id, :employee_user_id => self.employee_user_id, :owner_user_id => self.owner_user_id)
          repo_document = Document.new(:name => document_attributes[:name], :bookmark => document_attributes[:bookmark], :phase_id => document_attributes[:phase_id], :privilege => document_attributes[:privilege], :description => document_attributes[:description], :author => document_attributes[:author], :source => document_attributes[:source], :data => document_attributes[:data], :employee_user_id => self.employee_user_id, :created_by_user_id => self.employee_user_id, :company_id => self.company_id, :category_id => self.company.document_categories.find_by_lvalue('Other').id, :sub_category_id => company.document_sub_categories.find_by_lvalue('Other').id)
          repo_doc_home.documents <<  repo_document                   
        end
      else
        if access_rights_changed? &&  access_rights_was == 2
          remove_document_from_repository(self)
        elsif access_rights_changed? && access_rights == 2
          repo_doc_home= children.build(:mapable_type => 'Company', :mapable_id => company_id, :upload_stage => 1, :access_rights => 2, :company_id => self.company_id, :parent_id => id, :created_by_user_id => created_by_user_id, :employee_user_id => self.employee_user_id, :owner_user_id=> self.owner_user_id)
          latest_document = latest_doc
          path = File.join(latest_document.url, latest_document.data_file_name)
          data = File.open(path, "r")
          repo_document = latest_document.clone
          repo_document.data = data
          repo_document.employee_user_id = self.employee_user_id
          repo_document.created_by_user_id = self.created_by_user_id
          repo_document.company_id = self.company_id
          repo_document.category_id = self.company.document_categories.find_by_lvalue('Other').id
          repo_doc_home.documents << repo_document
        elsif !self.access_rights_changed? && self.access_rights == 2 && self.repo_update
          self.children.first.latest_doc.update_attributes(self.document_attributes) if self.children.first
          #FIXME :( Bug #10797
          doc_hm = DocumentHome.find(:first,:conditions => ["parent_id = ? AND company_id = ?", self.id, self.company_id])
          if doc_hm.present?
            dh_attr = self.clone.attributes.reject{|key, val| key == "mapable_id" || key == "mapable_type" || key == "parent_id"}
            doc_attr = self.latest_doc.clone.attributes.reject{|key, val| key == "document_home_id" || key == "category_id" || key == "sub_category_id"}
            doc_hm.tag_list = self.tag_list
            doc = doc_hm.latest_doc
            doc_hm.update_attributes(dh_attr)
            doc.update_attributes(doc_attr)
          end
        end
      end
    end
  end

  def superseed_document(doc_data, replace=false, bill=nil, check_in_doc=true)
    old_doc=self.latest_doc
    document= old_doc.clone
    document.created_at=nil
    if doc_data[:data]!= ''
      document.created_by_user_id = doc_data[:created_by_user_id]
      document.employee_user_id= doc_data[:employee_user_id]
      document.name = doc_data[:data].original_filename.gsub(/[.][^.]+$/,"") if replace
      document.data= doc_data[:data]
      document.description = doc_data[:description]
      document_home = DocumentHome.find(document.document_home_id)
      document_home.tag_list = doc_data[:tag_array]
      document_home.save!
      document.save!
      if self.repo_update
        repo_doc=old_doc.clone
        repo_doc.document_home_id= self.children.first.id if self.children.first
        repo_doc.data= doc_data[:data]
        repo_doc.save!
      end
      if replace and !bill.nil?
        comment= Comment.create(:title=> 'Invoice Updated',
          :company_id =>self.company_id,
          :created_by_user_id=> doc_data[:created_by_user_id],
          :commentable_id =>bill,
          :commentable_type=> 'MatterBilling',
          :comment =>'New invoice replaced')
        self.mapable_id = comment.id
        self.mapable_type = 'Comment'
        self.wip_doc = nil
        document.comment_id=comment.id
        document.save!
      elsif !bill.nil?
        comment= Comment.create(:title=> 'Invoice Updated',
          :company_id =>self.company_id,
          :created_by_user_id=> doc_data[:created_by_user_id],
          :commentable_id =>bill,
          :commentable_type=> 'MatterBilling',
          :comment =>'New invoice superseded')
        self.mapable_id = comment.id
        self.mapable_type = 'Comment'
        self.wip_doc = nil
        document.comment_id=comment.id
        document.save!
      end
      old_doc.destroy  if replace && !self.enforce_version_change
      self.checked_in_by_employee_user_id = nil
      self.checked_in_at = nil

      self.save if  check_in_doc
      true
    else
      false
    end
  end

  # Update self along with document.
  def update_with_document(doc_data)
    begin
      self.transaction do    
        document = doc_data.slice(
          :name, :phase_id, :bookmark, :privilege,
          :description, :author, :source,:doc_source_id,
          :employee_user_id, :created_by_user_id)
        document.merge!({
            :document_home_id => self.id,
            :doc_type_id => doc_data[:category_id]})
        doc= self.latest_doc
        if doc.update_attributes(document) && self.save
          true
        else
          doc.errors.each do |error|
            self.errors.add(error[0], error[1])
          end
          false
        end
      end
    rescue
      false
    end
  end

  def document_details
    self.latest_doc.name.try(:titleize)
  end
  
  def self.get_extensions(mapable_id, mapable_type)
    DocumentHome.connection.execute("select distinct(extension) from document_homes where extension is not null AND mapable_type='#{mapable_type}' AND mapable_id = #{mapable_id}").map{|e| e["extension"]}.sort
  end
  
  def set_extension
    unless self.documents.blank?
      ext_arr=self.documents.last.data_file_name.split('.')
      self.extension=ext_arr.last if ext_arr.count>1
    end
  end

  # Find document home records for given matter.
  def self.find_document_homes_for_matter(first, second)
    DocumentHome.all(:conditions => ["mapable_type = ? AND mapable_id = ? AND sub_type IS NULL", first, second ], :order => 'created_at DESC')
  end

  # Returns ToE document home
  def self.find_toe_document_home_for_matter(first, second)
    DocumentHome.last(:conditions => ["mapable_type = ? AND mapable_id = ? AND sub_type = 'Termcondition'", first, second ], :order => 'created_at DESC')
  end
  
  # Return latest version of attached document.
  def latest_doc
    self.documents.find_with_deleted(:first, :order => 'id DESC')
  end


  def self.checkout_email(doc_home, current_user)
    begin
      mail_body = <<EOT
Dear #{doc_home.checked_in_by.try(:full_name)},
Following document has been checked in by the lead lawyer:

Document Name:  #{doc_home.latest_doc.name}
Checked In By:#{current_user.full_name}

Thank you
EOT

      LiviaMailConfig::email_settings(current_user.company)
      mail = Mail.new()
      mail.from = "admin@liviaservices.com"
      mail.subject = "Document checked in by lead lawyer #{current_user.full_name}"
      mail.body =mail_body
      mail.to = doc_home.checked_in_by.email
      mail.deliver

      true
    rescue Timeout::Error => err
      puts "error"
      logger.info "Timeout Error"
      false
    rescue Exception => exec
      puts "error2"
      puts exec.message
      logger.info "Error while trying to send email"
      logger.info  exec.message
      false
    end
  end
  # for linking sub modules (risks/ facts/ tasks/ issues) - Supriya/ Mandeep
  def link_submodule(params, submodule)
    params[:document_home] ||= {}
    params[:document_home][submodule] ||= []
    self.update_attributes(params[:document_home])
  end

  def self.get_employee_additional_document(employee_id)
    all(:conditions => {:mapable_type => "AdditionalDocument", :mapable_id => employee_id}, :limit => 2)
  end

	# calculate offset for pagination if
  # folder is 40 and per page is 25
  # document is 35 so in page 2 15 folders and 10 document is displayed
  # so in next page offset set to 10
  # and if further document is possible offset becomes 10+25
  def self.calculate_offset(total_parent_entries, per_page, page_no)
    page_no ||= 1
    ((per_page.to_i * page_no.to_i) - ( total_parent_entries.to_i + per_page.to_i ))
  end
  # -5,25 if offset is negative i.e when displaying 20 folders and 5 documents

  def self.set_limit(offset, per_page)
    offset <= 0 ? offset + per_page.to_i : per_page.to_i
  end
  
  def self.round_to_zero(offset)
    offset <= 0 ? 0 : offset
  end

 
end

# == Schema Information
#
# Table name: document_homes
#
#  id                             :integer         not null, primary key
#  mapable_type                   :string(255)
#  mapable_id                     :integer
#  access_rights                  :integer
#  latest                         :integer
#  created_at                     :datetime
#  updated_at                     :datetime
#  sub_type                       :string(255)
#  sub_type_id                    :integer
#  upload_stage                   :integer
#  converted_by_user_id           :integer
#  delta                          :boolean         default(TRUE), not null
#  company_id                     :integer         not null
#  deleted_at                     :datetime
#  permanent_deleted_at           :datetime
#  created_by_user_id             :integer
#  updated_by_user_id             :integer
#  folder_id                      :integer
#  parent_id                      :integer
#  checked_in_by_employee_user_id :integer
#  checked_in_at                  :datetime
#  repo_update                    :boolean
#  enforce_version_change         :boolean
#  wip_doc                        :integer
#  employee_user_id               :integer
#  owner_user_id                  :integer

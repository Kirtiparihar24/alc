# desc "Explaining what the task does"
require 'fileutils'

namespace :wfm do
  
  WFM_JAVASCRIPT_DIRECTORY = File.join(RAILS_ROOT, '/public/javascripts/wfm/')
  WFM_CSS_DIRECTORY = File.join(RAILS_ROOT, '/public/stylesheets/wfm/')
  WFM_INSTALL_DIRECTORY =  File.join(RAILS_ROOT, '/vendor/plugins/wfm/')

  task :install do
    remove_files
    copy_css_files
    copy_js_files
  end

  def remove_files
    FileUtils.rm_r(WFM_JAVASCRIPT_DIRECTORY) if File.exist?(WFM_JAVASCRIPT_DIRECTORY)
    FileUtils.rm_r(WFM_CSS_DIRECTORY) if File.exist?(WFM_CSS_DIRECTORY)
  end

  def copy_css_files
    FileUtils.mkdir(WFM_CSS_DIRECTORY)
    source = WFM_INSTALL_DIRECTORY + 'public/stylesheets/'
    destination = WFM_CSS_DIRECTORY
    recursive_copy(:source => source, :dest => destination)
  end

  def copy_js_files
    FileUtils.mkdir(WFM_JAVASCRIPT_DIRECTORY)
    source = WFM_INSTALL_DIRECTORY + 'public/javascripts/'
    destination = WFM_JAVASCRIPT_DIRECTORY
    recursive_copy(:source => source, :dest => destination)
  end

  def recursive_copy(options)
    source = options[:source]
    dest = options[:dest]
    logging = options[:logging].nil? ? true : options[:logging]

    Dir.foreach(source) do |entry|
      next if entry =~ /^\./
      if File.directory?(File.join(source, entry))
        unless File.exist?(File.join(dest, entry))
          if logging
            puts "Creating directory #{entry}..."
          end
          FileUtils.mkdir File.join(dest, entry)#, :noop => true#, :verbose => true
        end
        recursive_copy(:source => File.join(source, entry),
          :dest => File.join(dest, entry),
          :logging => logging)
      else
        if logging
          puts "  Installing file #{entry}..."
        end
        FileUtils.cp File.join(source, entry), File.join(dest, entry)#, :noop => true#, :verbose => true
      end
    end
  end

  task :update_temporary_cluster_mappings => :environment do
    cluster_user_mappings = ClusterUser.find(:all)
    for cluster_user_mapping in cluster_user_mappings
      if cluster_user_mapping.to_date && cluster_user_mapping.to_date < Time.now
        livian_user = cluster_user_mapping.user
        cluster = cluster_user_mapping.cluster
        cluster_emplyee_users = cluster.lawyers
        for cluster_emplyee_user in cluster_emplyee_users
          Physical::Liviaservices::ServiceProviderEmployeeMappings.destroy_all(:service_provider_id => livian_user.service_provider.id, :employee_user_id => cluster_emplyee_user.id)
          SubproductAssignment.destroy_all(:user_id=>livian_user.id,:employee_user_id => cluster_emplyee_user.id)
        end
        cluster_user_mapping.destroy
      end
    end
  end

  task :update_manager_role_and_users => :environment do
    role = Role.find_by_name('manager')
    unless role.nil?
      manager_users = role.users
      Role.transaction do
        categories = Category.find_by_sql("select * from categories where name ilike 'livian%'")
        unless categories.blank?
          category = categories[0]
          role.update_attributes(:name=>'team_manager',:for_wfm=>true,:category_list=>{category.id.to_s=>"1"})
          for user in manager_users
            UserWorkSubtype.delete_all(:user_id=>user.id)
            for category in role.categories
              for work_type in category.work_types
                for work_subtype in work_type.work_subtypes
                  UserWorkSubtype.create(:user_id=>user.id,:work_subtype_id=>work_subtype.id)
                end
              end
            end
            service_provider = ServiceProvider.find_by_user_id(user.id)
            if service_provider.nil?
              ServiceProvider.create(:user_id=>user.id,:company_id=>user.company_id,:first_name=>"abc",:last_name=>"xyz")
            end
          end
        end
      end
    end
  end

  task :create_front_office_worksubtypes => :environment do
    category = Category.find(:first,:conditions=>"name ilike 'front%'")
    WorkType.transaction do
      work_type = WorkType.create(:name=>"Front Office Activity",:description=>"Fetched from company lookup",:category_id=>category.id)
      skills = CompanyLookup.find(:all,:select=>"lvalue",:conditions=>"type ilike '%skill%'")
      for skill in skills
        work_subtype = WorkSubtype.create(:name=>skill.lvalue,:description=>"Fetched from company lookup",:work_type_id=>work_type.id)
        WorkSubtypeComplexity.create(:work_subtype_id=>work_subtype.id,:stt=>1,:tat=>24)
        p work_subtype.name
      end
    end
    p "Front Office worksubtypes created successfully!"
  end

  task :create_back_office_worksubtypes => :environment do
    category = Category.find(:first,:conditions=>"name ilike 'back%'")
    WorkType.transaction do
      work_type = WorkType.create(:name=>"Back Office Activity",:description=>"Dummy Data",:category_id=>category.id)
      work_subtype = WorkSubtype.create(:name=>"Other",:description=>"Dummy Data",:work_type_id=>work_type.id)
      WorkSubtypeComplexity.create(:work_subtype_id=>work_subtype.id,:stt=>1,:tat=>24,:complexity_level=>1)
      p work_subtype.name
    end
    p "Dummy Back Office worksubtype created successfully!"
  end

  # this task should be run for liviaservices - live instance only
  task :create_front_office_worksubtypes_for_live => :environment do
    category = Category.find(:first,:conditions=>"name ilike 'front%'")
    WorkType.transaction do
      work_type = WorkType.create(:name=>"Front Office Activity",:description=>"",:category_id=>category.id)
      skills = CompanyLookup.find(:all,:select=>"lvalue",:conditions=>"type ilike '%skill%'")
      work_subtype_names = ["Contact Upload/Amend/Deactivate","Account Upload/Amend/Deactivate",
        "Create Opportunity/Amend/Deactivate","Matters Upload/Amend",
        "Time and Expense Upload","Campaigns Creation","Billing",
        "Reports and Dashboards","Workspace","Repository","General Secretarial Task"
      ]
      for work_subtype_name in work_subtype_names
        work_subtype = WorkSubtype.create(:name=>work_subtype_name,:description=>"",:work_type_id=>work_type.id)
        WorkSubtypeComplexity.create(:work_subtype_id=>work_subtype.id,:stt=>1,:tat=>24)
        p work_subtype.name
      end
    end
    p "Front Office worksubtypes created successfully!"
  end

  
  task :update_existing_tasks_for_work_subtype => :environment do
    skill_types =  Physical::Liviaservices::SkillType.all
    skill_type_ids = skill_types.map(&:id)
    tasks = UserTask.find(:all,:conditions=>["tasktype in (?) and deleted_at is null",skill_type_ids])
    work_type = WorkType.find(:first,:conditions=>["name='Front Office Activity'"])
    work_subtype = WorkSubtype.find(:first,:conditions=>["name='Other' and work_type_id=?",work_type.id])
    for task in tasks
      task.work_subtype_id = work_subtype.id
      task.save
    end
  end

  task :add_default_questions_in_company_lookups => :environment do
    CompanyLookup.connection.execute "INSERT INTO company_lookups (type,lvalue,company_id,alvalue) values('DefaultQuestion','Who invented the world wide web?',1,'Sir Tim Berners-Lee');
             INSERT INTO company_lookups (type,lvalue,company_id,alvalue) values('DefaultQuestion','Which is the brightest star in the southern constellation of Centaurus?',1,'Alpha Centauri');"
  end

  task :assign_default_security_question_to_existing_lawfirm_users => :environment do
    lawfirm_users = User.find(:all, :include => [:employee], :conditions => ["users.id = employees.user_id"])
    default_questions = CompanyLookup.find(:all,:conditions=>['type=?','DefaultQuestion'])
    first_default_question = default_questions[0].lvalue
    second_default_question = default_questions[1].lvalue
    first_default_answer = default_questions[0].alvalue
    second_default_answer = default_questions[1].alvalue
    lawfirm_users.each do |lawfirm_user|
      first_security_question = lawfirm_user.questions.create(:setting_value=>first_default_question,:setting_type=>'Question',:company_id=>lawfirm_user.company_id)
      second_security_question = lawfirm_user.questions.create(:setting_value=>second_default_question,:setting_type=>'Question',:company_id=>lawfirm_user.company_id)
      first_security_question.create_answer(:setting_value=>first_default_answer,:setting_type=>'Answer',:company_id=>lawfirm_user.company_id,:user_id=>lawfirm_user.id)
      second_security_question.create_answer(:setting_value=>second_default_answer,:setting_type=>'Answer',:company_id=>lawfirm_user.company_id,:user_id=>lawfirm_user.id)
    end
  end

  task :update_upcoming_setting_type_in_user_settings => :environment do
    upcoming_setting_types = UserSetting.find_all_by_setting_type('upcoming')
    upcoming_setting_types.each do |upcoming_setting_type|
      upcoming_setting_type.update_attribute(:setting_type, 'Upcoming')
    end
  end

  task :add_livians_not_assigned_to_any_cluster_to_common_pool => :environment do
    common_pool_cluster = Cluster.find_by_name('Common Pool')
    ServiceProvider.all.each do |sp|
      sp_user = sp.user
      if sp_user.clusters.blank?
        ClusterUser.create(:cluster_id => common_pool_cluster.id, :user_id => sp_user.id)
      end
    end
  end

  task :set_provider_type_of_livians => :environment do
    common_pool_cluster = Cluster.find_by_name('Common Pool')
    livian_clusters = Cluster.all - common_pool_cluster.to_a
    livian_clusters_names = livian_clusters.map(&:name)
    ServiceProvider.all.each do |sp|
      sp_clusters_names = []
      sp.user.clusters.uniq.collect{|c| sp_clusters_names << c.name}
      if sp_clusters_names.include?(common_pool_cluster.name) && sp_clusters_names.to_set.subset?(livian_clusters_names.to_set)
        sp.provider_type = 5
      elsif (sp_clusters_names - common_pool_cluster.name.to_a).empty?
        sp.provider_type = 4
      else
        sp.provider_type = 1
      end
      sp.send(:update_without_callbacks)
    end
  end

  task :set_cluster_type_for_clusters  => :environment do
    clusters = Cluster.all
    cp_cluster_arr = clusters.select{|c| c.name == 'Common Pool'}
    clusters -= cp_cluster_arr
    cp_cluster = cp_cluster_arr[0]
    cp_cluster.update_attribute(:cluster_type,4)
    for cluster in clusters
      cluster.update_attribute(:cluster_type,1)
    end
  end

  task :set_time_zone_of_tasks => :environment do
    tasks_without_tz = UserTask.find_all_by_time_zone(:conditions=>'time_zone IS NULL')
    tasks_without_tz.each do |task|
      task.update_attribute(:time_zone,task.logged_by.time_zone) if task.logged_by.present?
    end
  end

  # Updates status of recurring parent task status to complete, if end date is reached
  task :complete_recurring_tasks => :environment do
    tasks = UserTask.find(:all,:conditions=>["repeat in ('DAI','WEE','MON','ANU') and status is null and end_at <?",Date.today])
    unless tasks.blank?
      tasks.each do |task|
        task.update_attributes(:status=>'complete')
      end
    end
  end

  # updating original start date of of recurring task instances with start date
  # as we are making start date editable from un editable 
  task :update_original_start_date_of_recurring_task_instance => :environment do
    tasks = UserTask.find(:all,:conditions=>["repeat in ('DAI','WEE','MON','ANU')"])
    for task in tasks
      repeat_instances = UserTask.find(:all,:conditions=>["name = ? AND parent_id = ?",task.name,task.id])
      for repeat_instance in repeat_instances
        repeat_instance.update_attribute(:original_start_at,repeat_instance.start_at)
      end
    end
  end
end

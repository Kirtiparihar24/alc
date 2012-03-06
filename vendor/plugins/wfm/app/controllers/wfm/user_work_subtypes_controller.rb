# To Assign/Unassign Skills to cluster users(ServiceProviders)

class Wfm::UserWorkSubtypesController < WfmApplicationController
  before_filter :authenticate_user!
  before_filter :get_default_data, :only=>[:index, :skills_by_livians, :skills_by_backoffice_agents]
  before_filter [:get_alert_task_counts ,:get_user_notifications], :only => [:index, :skills_by_livians, :skills_by_backoffice_agents]
  layout 'wfm'

  def index
    livian_users = []
    @work_subtypes = WorkSubtype.all.uniq
    if is_cpa? || is_common_pool_team_manager?
      @lawfirm_users = Employee.get_all_employee_users
    else
      @lawfirm_users = @assigned_lawfirm_users
    end
    current_user.clusters.each do |cluster|
      livian_users += cluster.livians
    end
  end

  # this action is triggered on lawyers dropdown onchange event to get the lawyers clusters, it's livians and their skills
  def get_clusters_livians_and_skills_for_selected_lawyer
    lawfirm_user = User.find(params[:lawfirm_user_id])
    @lawfirm_users_clusters = []
    @lawfirm_users_livians = []
    @livians_skills = []
    for cluster in  lawfirm_user.clusters
      @lawfirm_users_clusters << cluster
      @lawfirm_users_livians += cluster.livians
    end
    @lawfirm_users_livians.uniq!
    @lawfirm_users_livians = sort_by_first_name_and_last_name(@lawfirm_users_livians) unless @lawfirm_users_livians.blank?
    for livian in @lawfirm_users_livians
      @livians_skills += livian.work_subtypes
    end
    @livians_skills.uniq!
    @unassigned_skills = WorkSubtype.all - @livians_skills
    render :update do |page|
      unless @lawfirm_users_clusters.blank? || @lawfirm_users_livians.blank?
        page.replace_html 'clusters_of_selected_lawyer',:partial => "clusters_of_selected_lawyer"
        page.replace_html 'livians_of_lawyers_clusters',:partial => "livians_of_lawyers_clusters"
        page.replace_html 'livians_skills',:partial => "livians_skills"
      else
        page.replace_html 'clusters_of_selected_lawyer',:text=>"No Clusters / Livians are assigned to #{lawfirm_user.full_name}"
        page.replace_html 'livians_of_lawyers_clusters',:text=>""
        page.replace_html 'livians_skills',:text=>""
      end
    end
  end

  #  this action is triggered on selecting cluster(s) to get the cluster's livians & their skills
  def get_livians_and_skills
    cluster_ids = params[:clusters]
    clusters_livian_users = []
    livians_skills = []
    cluster_ids.each do |cluster_id|
      cluster = Cluster.find cluster_id
      clusters_livian_users += cluster.livians
    end
    @lawfirm_users_livians = clusters_livian_users.uniq
    @lawfirm_users_livians.each do |livian|
      livians_skills += livian.work_subtypes
    end
    @livians_skills = livians_skills.uniq
    @unassigned_skills = WorkSubtype.all - @livians_skills
    render :update do |page|
      page << "loader.remove();"
      unless clusters_livian_users.blank?
        page.replace_html 'livians_of_lawyers_clusters',:partial => "livians_of_lawyers_clusters"
        page.replace_html 'livians_skills',:partial => "livians_skills"
      else
        page.replace_html 'livians_of_lawyers_clusters',:text => "No Livians are assigned to the selected cluster(s)"
        page.replace_html 'livians_skills',:text => ""
      end
    end
  end

  def get_livians_skills
    livian_user_ids = params[:livians]
    livians_skills = []
    livian_user_ids.each do |livian_user_id|
      livian_user = User.find livian_user_id
      livians_skills += livian_user.work_subtypes
    end
    @livians_skills = livians_skills.uniq
    @unassigned_skills = WorkSubtype.all - @livians_skills
    render :update do |page|
      page.replace_html 'livians_skills',:partial => "livians_skills"
      page << "loader.remove();"
    end
  end

  def update_livian_skills
    livians = User.find(params[:livians])
    if params[:assign_or_unassign] == 'assign'
      for livian_id in params[:livians]
        for skill_id in params[:unassigned_skills]
          user_skill = UserWorkSubtype.find_by_user_id_and_work_subtype_id(livian_id,skill_id)
          UserWorkSubtype.create(:user_id=>livian_id,:work_subtype_id=>skill_id) unless user_skill
        end
      end
    end
    if params[:assign_or_unassign] == 'unassign'
      for livian_id in params[:livians]
        for skill_id in params[:livian_skills]
          UserWorkSubtype.delete_all(:user_id=>livian_id,:work_subtype_id=>skill_id)
        end
      end
    end
    @livians_skills = []
    for livian in livians
      @livians_skills += livian.work_subtypes
    end
    @livians_skills.uniq!
    @unassigned_skills = WorkSubtype.all - @livians_skills
    render :update do |page|
      page.replace_html 'livians_skills',:partial => "livians_skills"
    end
  end

  def update_skills
    cluster_livians = User.get_users_cluster_livians(current_user)
    if params.include?("back_office_skills")
      cluster_livians.each do |u|
        WorkSubtype.back_office_work_subtypes.each do |w|
          UserWorkSubtype.destroy_all(:user_id => u.id, :work_subtype_id => w.id)
        end
      end
      unless params[:complexity_level_ids].blank?
        update_complexity_params = params[:complexity_level_ids]
        update_complexity_params.delete_if {|x| x == "" }
        update_complexity_params.each do |update_complexity_param|
          split_array = update_complexity_param.split('-')
          work_subtype = WorkSubtype.find(split_array[1], :include =>[:work_subtype_complexities])
          complexity_level = work_subtype.work_subtype_complexities.find(:first, :conditions => {:complexity_level => split_array[2]})
          work_subtype.user_work_subtypes.create(:user_id => split_array[0], :work_subtype_complexity_id => complexity_level.id)
        end
      end
    else
      assigned_skills_array = get_assigned_front_office_skills_array(cluster_livians)
      unless params[:livian_skill_mappings].blank?
        for new_skill in params[:livian_skill_mappings]
          unless assigned_skills_array.include?(new_skill)
            ids = new_skill.split('-')
            UserWorkSubtype.create(:user_id=>ids[0],:work_subtype_id=>ids[1])
          end
        end
        for assigned_skill in assigned_skills_array
          unless params[:livian_skill_mappings].include?(assigned_skill)
            ids = assigned_skill.split('-')
            UserWorkSubtype.destroy_all(:user_id=>ids[0],:work_subtype_id=>ids[1])
          end
        end
      else
        UserWorkSubtype.destroy_all("user_id in (#{cluster_livians.map(&:id).join(',')})")
      end
    end
    flash[:notice] = "Skills updated successfully"
    if params.include?("back_office_skills")
      redirect_to skills_by_backoffice_agents_wfm_user_work_subtypes_path
    else
      redirect_to skills_by_livians_wfm_user_work_subtypes_path
    end
  end

  def skills_by_livians
    @cluster_livians = User.get_users_cluster_livians(current_user)
    @livian_work_subtypes = WorkSubtype.front_office_work_subtypes
  end

  def skills_by_backoffice_agents
    @cluster_livians = User.get_users_cluster_livians(current_user)
    @back_office_work_subtypes = WorkSubtype.back_office_work_subtypes
  end

  private

  def get_skills(option)
    category = Category.find_by_name(option)
    skills = category.work_types.map(&:work_subtypes)
    return skills.flatten
  end

  def get_assigned_front_office_skills_array(users)
    front_office_work_subtypes = WorkSubtype.front_office_work_subtypes
    user_work_subtypes = UserWorkSubtype.find(:all, :conditions=>["user_id in (?) and work_subtype_id in (?)",users.map(&:id),front_office_work_subtypes.map(&:id)])
    arr = []
    for uws in user_work_subtypes
      arr << uws.user_id.to_s + "-" + uws.work_subtype_id.to_s
    end
    arr
  end

  def sort_by_first_name_and_last_name(users)
    users.sort! { |a,b| [a.first_name.downcase,a.last_name.downcase] <=> [b.first_name.downcase,b.last_name.downcase] }
  end
end

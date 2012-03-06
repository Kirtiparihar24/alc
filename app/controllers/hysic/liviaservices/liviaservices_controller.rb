class Physical::Liviaservices::LiviaservicesController < ApplicationController
  before_filter :authenticate_user!
  
  layout 'admin'
  # Below code Loads first 
  # needs to be deprecated
  def managers_portal
    authorize!(:managers_portal,current_user) unless current_user.role?:manager
    update_session
    @secratary =ServiceProvider.find(:all) 
    @sp_list = @secratary
    @total_notes_count = Communication.count(:conditions=>["(status is null  or status != 'complete')"])
    @tasks = UserTask.find(:all,:conditions=>["status is null  or status != 'complete'"],:order => "created_at")
    @total_task_count = @tasks.size
    @task_unassigned_count = @tasks.select{|task| task.assigned_to_user_id.blank? && (task.status == nil  or task.status != 'complete')}.size
    @task_unassigned_oldest = @tasks.select{|task| task.assigned_to_user_id.blank? && (task.status == nil  or task.status != 'complete')}.last
  end

  # Below code is used to show secratary details.
  def managers_select_option
    user_name = params[:secratary_id].blank? ? nil : User.get_user_name(params[:secratary_id])
    render :partial =>'managers_option', :locals=>{:user_name=>user_name}
  end

  # Below code is used to show all the task related to selected secretary.
  def secratary_details_task_list
    @tasks = UserTask.get_all_secratary_details_task_list(params[:secratary_id])
    @user_name = params[:secratary_id].blank?? nil : User.get_user_name(params[:secratary_id])
    @skills_types = Physical::Liviaservices::SkillType.find(:all)
    render :partial =>'secratary_details_task_list'    
  end

  # Below code is used to show all the notes related to selected secretary.
  def secratary_details_notes_list
    @notes= Communication.get_secratary_details_notes_list(params[:secratary_id])
    @skill_types = Physical::Liviaservices::SkillType.find(:all)
    @user_name = params[:secratary_id].blank? ? nil : User.get_user_name(params[:secratary_id])
    render :partial =>'secratary_details_notes_list'    
  end

  # Below code is used to update the tasks.
  def update_tasks
    UserTask.update(params[:task].keys, params[:task].values)
    flash[:notice] = "#{t(:text_task)} " "#{t(:flash_was_successful)} " "#{t(:text_assigned)}"
    redirect_to physical_liviaservices_managers_portal_path
  end

  # Below code is used to update the notes.
  def update_notes
    tasks = params[:task].values.collect{ |tasks|
      UserTask.new(tasks.merge!(:created_by_user_id=>current_user.id,:priority=> tasks[:priority].nil? ? 1:2)) }
    tasks.each do |tasks|
      unless tasks.assigned_to_user_id.blank?
        if tasks.save
          com_notes_entries = Communication.find(tasks.note_id.to_i)
          com_notes_entries.update_attributes(:status => 'complete')
          flash[:notice] = "#{t(:text_notes)} " "#{t(:flash_was_successful)} " "#{t(:text_assigned)}"
        else
          flash[:error] = "Task Type should not be empty!"
        end
      end
    end    
    redirect_to physical_liviaservices_managers_portal_path
  end

  # Methods for skill assignment.
  def pick_skills_for_lilly
    assigned_skills = []
    unassigned_skills = []
    unless params[:sp_id].nil? or params[:sp_id].blank?
      assigned_skills = ServiceProvider.find(params[:sp_id]).skills.collect {|e| e.skill}
      unassigned_skills = Physical::Liviaservices::SkillType.find(:all).find_all {|e| !assigned_skills.include?(e)}
    end
		sp_list = ServiceProvider.find(:all)
    sp_id = params[:sp_id]
		render :partial => "assign_skill", :locals=> {:sp_list=>sp_list, :sp_id=>sp_id, :assigned_skills=>assigned_skills,:unassigned_skills=>unassigned_skills}
	end

  def assign_skills
    skills = params[:skills].split(";")
    sp_id = params[:sp_id]
    cid = current_company.id
    skills.each do |e|
      skill = Physical::Liviaservices::ServiceProviderSkill.new
      skill.service_provider_id = sp_id
      skill.skill_type_id = e
      skill.company_id = cid
      skill.save
    end
		rendering_to_assign_skill
  end

  def unassign_skills
    skills = params[:skills].split(";").collect {|e| e.to_i}
    sp_id = params[:sp_id].to_i
    Physical::Liviaservices::ServiceProviderSkill.delete_all(["service_provider_id=? and skill_type_id in (?)", sp_id, skills])
		rendering_to_assign_skill
  end

  def rendering_to_assign_skill
 		assigned_skills = ServiceProvider.find(params[:sp_id]).skills.collect {|e| e.skill}
    unassigned_skills = Physical::Liviaservices::SkillType.find(:all).find_all {|e| !assigned_skills.include?(e)}
		sp_list = ServiceProvider.find(:all)
    sp_id = params[:sp_id]
	  render :partial => "assign_skill", :locals=>{:assigned_skills=>assigned_skills,:unassigned_skills=>unassigned_skills,:sp_list=>sp_list,:sp_id=>sp_id}

  end

  def about
    render :layout => false
  end
  
end
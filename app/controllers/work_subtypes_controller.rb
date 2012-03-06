class WorkSubtypesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :get_categories
  before_filter :get_work_subtype, :only => [:edit, :update,:destroy]
  before_filter :check_tasks, :only => [:check_tasks_on_work_complexities, :work_complexities]
  
  layout 'admin'

  def index
    unless params[:filter]
      @work_subtypes = WorkSubtype.all
    else
      @work_subtypes = params[:filter].eql?('Back Office') ? WorkSubtype.back_office_work_subtypes : WorkSubtype.front_office_work_subtypes
    end
    @work_subtypes = @work_subtypes.paginate :page => params[:page], :per_page => 20
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @work_subtypes }
    end
  end

  def new
    @work_subtype = WorkSubtype.new
    @work_subtype.work_subtype_complexities.build
    @work_types = WorkType.all
  end

  def edit
    cat = Category.find(@work_subtype.work_type.category.id)
    @work_types = cat.work_types
  end

  def create

    @work_subtype = WorkSubtype.new(params[:work_subtype])
  
    #    @work_subtype.stt = true if params[:work_subtype][:new_work_subtype_complexity_attributes].present? && params[:work_subtype][:new_work_subtype_complexity_attributes][0][:stt] == ""
    #    @work_subtype.tat = true if params[:work_subtype][:new_work_subtype_complexity_attributes].present? && params[:work_subtype][:new_work_subtype_complexity_attributes][0][:tat] == ""
    #    @work_subtype.complexity_level = true if params[:work_subtype][:new_work_subtype_complexity_attributes].present? && params[:work_subtype][:new_work_subtype_complexity_attributes][0][:complexity_level] == ""
    @category = Category.find(params[:category]) if params[:category].present?
    
    if @work_subtype.save
      flash[:notice] = 'WorkSubtype was successfully created.'
      render :update do |page|
        page.redirect_to work_subtypes_url
      end
    else
      render :update do |page|
        page.replace_html 'error_div', "<div class='errorCont'>#{@work_subtype.errors.full_messages.join('<br>')}</div>"
      end
    end
  end


  def update
    @work_types = WorkType.all
    params[:work_subtype][:existing_work_subtype_complexity_attributes] ||= {}
    if @work_subtype.update_attributes(params[:work_subtype])
      flash[:notice] = 'WorkSubtype was successfully updated.'
      render :update do |page|
        page.redirect_to work_subtypes_url
      end
    else
      render :update do |page|
        page.replace_html 'error_div', "<div class='errorCont'>#{@work_subtype.errors.full_messages.join('<br>')}</div>"
      end
    end
  end


  def destroy
    @work_subtype.destroy
    render :update do |page|
      page.redirect_to(work_subtypes_url)
    end
  end

  def get_category_work_types
    @category = Category.find(params[:category_id])
    @work_types = @category.work_types
  end

  def check_tasks_on_work_complexities
    render :update do |page|
      if @open_tasks.blank? && @complete_tasks.blank?
        if params[:class_type] == 'WorkSubtypeComplexity'
          page << "jQuery('##{params[:id]}').remove();tb_remove();"
        else
          page << "delete_work_subtype(#{params[:id]},false);"
        end
      else
        page << "tb_show('Comfirm','/work_subtypes/work_complexities/#{@obj.id}?height=200&width=400&class_type=#{params[:class_type]}',''); "
      end
    end
  end
  
  def work_complexities
    render :layout => false
  end

  private

  def get_categories
    @categories = Category.all
  end

  def get_work_subtype
    @work_subtype = WorkSubtype.find(params[:id])
  end

  def check_tasks
    @obj = params[:class_type].constantize.find(params[:id])
    @open_tasks = @obj.user_tasks.find(:all ,:conditions => ['status IS NULL'])
    @complete_tasks = @obj.user_tasks.find(:all, :conditions => ['status IS NOT NULL'])
  end
  
end

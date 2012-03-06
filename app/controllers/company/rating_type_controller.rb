class Company::RatingTypeController < ApplicationController
  before_filter :authenticate_user!  
  before_filter :filter_contacts
  before_filter :get_company
  before_filter "url_check('rating_type')",:only=>:index

  layout "admin"

  def index
  end

  def new
    @rating_type = RatingType.new
    render :layout=>false
  end

  def create
    @rating_type = RatingType.new(params[:rating_type].merge(:lvalue=>params[:rating_type][:alvalue]))
    @rating_type.valid?
    @rating_type.validate_stage_name(@company,@rating_type.lvalue)
    if  @rating_type.errors.empty?
      @company.rating_type = @rating_type
    end
    render :update do |page|
      unless !@rating_type.errors.empty?
        page.replace_html('list', :partial =>"/company/rating_type/list")
        page<< 'tb_remove();'
        page.call('common_flash_message_name_notice', "Rating Type was successfully created")
      else
        page.call('show_msg','nameerror',@rating_type.errors.on(:lvalue))
      end
    end
  end

  def edit
    @rating_type = RatingType.find_by_id params[:id]
    render :layout=>false
  end

  def update
    @rating_type = RatingType.find(params[:id])
    @rating_type.attributes = params[:rating_type].merge(:lvalue=>params[:rating_type][:alvalue])
    @rating_type.valid?
    if @rating_type.errors.empty?
      @rating_type.save
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          unless !@rating_type.errors.empty?
            page.replace_html('list', :partial =>"/company/rating_type/list")
            page<< 'tb_remove();'
            page.call('common_flash_message_name_notice', "Rating Type was successfully updated")
            page<<"window.location.href='#{manage_company_utilities_path('rating_type',:linkage=>'rating_type')}';"
          else
            page.call('show_msg','nameerror',@rating_type.errors.on(:lvalue))
          end
        end
      }
    end
  end
  
end

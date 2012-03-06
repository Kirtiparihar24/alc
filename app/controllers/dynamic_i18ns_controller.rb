class DynamicI18nsController < ApplicationController
  before_filter :load_redis
  layout 'admin'
  def index
    @companies = DynamicI18n.get_companies.to_a    
    if params[:company].present?
      @company_key = params[:company]
    else
      @company_key = "en"
    end
    @translations = DynamicI18n.find_all("#{@company_key}.*")
  end
 
  def add
    @key = params[:i18n]+"."+params[:key]
    if params[:i18n] == "en"
      DynamicI18n.i18n_add_to_master(@key,params[:value])
    else
      DynamicI18n.create(@key,params[:value])
    end
    @value = DynamicI18n.find(@key) 
    respond_to do |format|
      format.js
    end 
  end

  def modify
    DynamicI18n.create(params[:id],params[:value])
    render :text => DynamicI18n.find(params[:id]) 
  end
  
  def remove
    DynamicI18n.destroy(params[:key])
  end
  
  def replace_word
    if params[:company]
      search_key = "#{params[:company]}.*"
      company_key = params[:company]
    else
      search_key = "*"
      company_key = "en"
    end
    DynamicI18n.search_and_replace_word(params[:search_value],params[:replace_value],search_key)
    redirect_to dynamic_i18ns_path(:company=>company_key)
  end 
 
  private
  def load_redis
    @redis = DynamicI18n.redis_con
  end

end

include DocumentHomesHelper
class AssetsController < ApplicationController
  before_filter :authenticate_user!  
  before_filter :current_service_session_exists

  def show
    unless is_client
      asset = Asset.scoped_by_company_id.find(params[:id])
      if check_for_file_existence?(asset)
        doc_home = asset.document.document_home if asset
        if params[:deleted_doc]
          doc_home = DocumentHome.find_with_deleted(asset.document.document_home_id)
        end
        if asset && @current_user.has_access?(Asset::DOCUMENT_TO_PRODUCT[doc_home.mapable_type]) && document_accesible?(doc_home)
          # do security check here
          send_file asset.data.path, :type => asset.data_content_type, :length=>asset.data_file_size, :disposition => 'attachment'.freeze
        elsif doc_home.upload_stage==2 &&  asset && @current_user.has_access?(Asset::DOCUMENT_TO_PRODUCT[doc_home.mapable_type]) &&  document_accesible?(doc_home)
          send_file asset.data.path, :type => asset.data_content_type, :length=>asset.data_file_size, :disposition => 'attachment'.freeze
        else
          flash[:error]= t(:flash_access_denied)
          redirect_to :back
        end
      else
        flash[:error]= 'File Not Found'
        redirect_to :back
      end
    else
      asset = Asset.scoped_by_company_id(params[:company_id]).find(params[:id])
      if check_for_file_existence?(asset)
        doc_home=asset.document.document_home if asset
        contact_id=Matter.scoped_by_company_id(params[:company_id]).find(doc_home.mapable_id).contact_id
        if asset && access_right_client(doc_home.id, contact_id)
          # do security check here
          send_file asset.data.path, :type => asset.data_content_type, :length=>asset.data_file_size, :disposition => 'attachment'.freeze
          # @mandeep: Fallback option for old ToE docs which did not have access rights set for client access.
        elsif asset && doc_home.sub_type && doc_home.sub_type.eql?('Termcondition')
          send_file asset.data.path, :type => asset.data_content_type, :length=>asset.data_file_size, :disposition => 'attachment'.freeze
        else
          flash[:error]= t(:flash_access_denied)
          redirect_to :back
        end
      else
        flash[:error]= 'File Not Found'
        redirect_to :back
      end
    end
  rescue
    flash[:error]= t(:flash_access_denied)
    redirect_to root_url
  end

  def check_for_file_existence?(asset)
    unless asset.nil?
      asset_file = RAILS_ROOT + "/#{asset.url}/#{asset.name}"
      return true if File.exist?(asset_file)
    end
    false
  end
  
end

class Zimbra::Usersapi::ZimbraAttachmentController < ApplicationController

  #NEED TO BE REFACTORED
  #This action is called in zimlet window iframe when a save attachment link beside mail attachment is clicked
  #This action uploads the mail attachment based on upload_to parameter to contacts,accounts, opportunity,matters,campaigns
  #Working:- download_attachment action downloads the mail attachment to RAILS_ROOT/zimbra_attachment folder
  #merge_data method call prepares the parameter for uploading document based upon upload_to parameter
  #save_with_document method call saves this document to specified module
  #Author: Sanil Naik Date:-8th April 2010
  skip_before_filter :verify_authenticity_token
  
  def upload_mail_attachment
    if request.get?
      render :partial=>'upload_form',:layout=>false
    end
    if  request.post?
      params[:user_email_id] = "mkd@ddiplaw.com" if params[:user_email_id].eql?("mdickinson@mdick.liviaservices.com")
      begin
        partarr=params[:part].split(",")
        file_namearr=params[:file_name].split(",")
        descriptionarr = []
        descriptionarr=params[:description].split(",") if params[:description].present?
        partarr.each_index do |i|
          options={:msg_id=>params[:msg_id],:file_name=>file_namearr[i],
            :part_id=>partarr[i],:user_email_id=>params[:user_email_id],
            :msg_date=>params[:msg_date],:subject=>params[:subject],
            :to=>params[:to],:from=>params[:from]}
          ZimbraAttachment.download_attachment(options)
          data=merge_data(file_namearr[i],partarr[i],descriptionarr[i])
          doc_home = DocumentHome.new(data)
          doc_home.documents.build(data[:document_attributes])
          if doc_home.save
            flash[:notice]="File Successfully uploaded."            
          end
        end       
        ZimbraAttachment.delete_attachments(params[:user_email_id]+":"+params[:msg_id])
      rescue Exception=>e
        flash[:error]=e
      end
      render :partial=>'upload_form',:layout=>false
    end
  end

  def merge_data(file_name,part,description)
    params[:user_email_id] = "mkd@ddiplaw.com" if params[:user_email_id].eql?("mdickinson@mdick.liviaservices.com")
    user = User.find_by_email(params[:user_email_id])    
    if part.eql?("0")
      file = File.open("#{RAILS_ROOT}/zimbra_attachment/#{params[:user_email_id]}:#{params[:msg_id]}/#{file_name}.zip", 'r')
    elsif part.eql?("1")
      file = File.open("#{RAILS_ROOT}/zimbra_attachment/#{params[:user_email_id]}:#{params[:msg_id]}/#{file_name}.txt", 'r')
    else
      file = File.open("#{RAILS_ROOT}/zimbra_attachment/#{params[:user_email_id]}:#{params[:msg_id]}/#{file_name}", 'r')
    end
    data={:created_by_user_id=>user.id,
      :company_id => user.company.id, :employee_user_id => user.id ,
      :access_rights => 2,
      :owner_user_id => user.id,
      :document_attributes => {:data => file,:description => (description || "Mail Attachment"),
        :name => file_name, :author => user.full_name,:source=>'email',
        :company_id => user.company.id, :employee_user_id => user.id,
        :created_by_user_id => user.id}
    }
    case  params[:upload_to]
    when "opportunities"
      raise "Please specify Opportunity " unless  params[:opportunity][:id].present?
      data.merge!(:mapable_id=>params[:opportunity][:id],
        :mapable_type=>"Opportunity")
    when "contacts"
      raise "Please specify Contact " unless  params[:contact][:id].present?
      data.merge!(:mapable_id=>params[:contact][:id],
        :mapable_type=>"Contact"#,
        #:document_attributes['description'] => (params[:contact][:description] ||description ||"Mail Attachment")
      )
    when "accounts"
      raise "Please specify Account " unless  params[:account][:id].present?
      data.merge!(:mapable_id=>params[:account][:id],
        :mapable_type=>"Account")
    when "campaigns"
      raise "Please specify Campaign " unless  params[:campaign][:id].present?
      data.merge!(:mapable_id=>params[:campaign][:id],
        :mapable_type=>"Campaign" )
    when "matters"
      raise "Please specify Matters " unless  params[:matter][:id].present?
      data.merge!(:access_rights=>1,
        :mapable_id=>params[:matter][:id],
        :mapable_type=>"Matter",
        :user_ids=>[user.id],:upload_stage => 1)
    when "public_document"      
      data.merge!(:mapable_id=>user.company_id,
        :mapable_type=>"Company" )
    end
    return data
  end

  def get_company_name
    params[:user_email_id] = "mkd@ddiplaw.com" if params[:user_email_id].eql?("mdickinson@mdick.liviaservices.com")
    user=User.find_by_email(params[:user_email_id])
    if user
      render :xml=> {:company_name=> user.company.name,:company_id=> user.company.id}
    else
      render :xml=> {:error => "Company not found"}
    end  
  end
 
end

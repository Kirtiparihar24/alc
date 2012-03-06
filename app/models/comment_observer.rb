class CommentObserver < ActiveRecord::Observer
  observe  :contact,:account,:opportunity,:matter, :tne_invoice,:matter_billing ,"Physical::Timeandexpenses::TimeEntry".constantize, "Physical::Timeandexpenses::ExpenseEntry".constantize
  def after_update(object)
    if object.instance_of?(Contact)
      user = User.find_by_id(object.created_by_user_id.to_i)
      if object.assigned_to_employee_user_id_changed? && user !=object.assignee
        send_notification_to_responsible(object.assignee,object,user) unless user.nil?
      end
    elsif object.instance_of?(Matter)
      return if object.skip_notification
      send_notification_for_matter(object, false)
    end
  end
  
  def after_create(record)
    title=record.class.table_name.singularize.try(:titleize) + ' Created' unless  record.class.name.eql?("TneInvoice") || record.class.name.eql?("MatterBilling")
    if record.class.name.eql?("TneInvoice")
      title= 'Invoice Created'
      comment_text=   'Created Invoice ' + record.invoice_no
    elsif record.class.name.eql?("MatterBilling")
      unless record.bill_id.blank?
        bill = MatterBilling.first(:conditions => ["bill_id= #{record.bill_id} AND company_id IS NOT NULL AND created_by_user_id IS NOT NULL"])
        status_was = TneInvoiceStatus.find_by_id(bill.matter_billing_status_id).alvalue.try(:titleize)
        status_is = TneInvoiceStatus.find_by_id(record.matter_billing_status_id).alvalue.try(:titleize)
        comment_type= bill.automate_entry? ? 'TneInvoice' : record.class.name
        comment_id= bill.automate_entry? ? bill.tne_invoice_id : bill.id
        if (record.bill_amount_paid && record.bill_amount_paid !=0 && status_was != status_is)
          comment_text = "Amount Settled $  #{record.bill_amount_paid.to_s} on #{record.bill_pay_date} and Status changed to #{status_is} reason being #{record.remarks}"
          comment_title = 'Amount Settled/Status Updated'
        elsif(status_was != status_is)
          comment_text = "Invoice updated from #{status_was} to #{status_is} reason being #{record.remarks}"
          comment_title = 'Status Updated'
        elsif (record.bill_amount_paid && record.bill_amount_paid !=0)
          comment_text = "Amount Settled $   #{record.bill_amount_paid.to_s}  on #{record.bill_pay_date}"
          comment_title = 'Amount Settled'
        end
        Comment.create(:title=> comment_title,
          :company_id =>bill.company_id,
          :created_by_user_id=> bill.created_by_user_id,
          :commentable_id =>comment_id,
          :commentable_type=> comment_type,
          :comment =>comment_text)
      else
        title= 'Invoice Created'
        comment_text=   'Created Invoice ' + record.bill_no
      end
    elsif record.class.name.eql?("Physical::Timeandexpenses::TimeEntry")
      comment_text=   'Created - ' + record.description
    elsif record.class.name.eql?("Physical::Timeandexpenses::ExpenseEntry")
      comment_text=   'Created - ' + record.description
    else
      comment_text=   'Created ' + record.class.name.try(:titleize) + " " + record.name.try(:titleize)
    end
    comment_text=comment_text+" Comment: " + "#{record.user_comment}" if record.class.name.eql?("Contact") && record.user_comment.present?
    comment = Comment.create(:title=> title,
      :company_id =>record.company_id,
      :created_by_user_id=> record.created_by_user_id,
      :commentable_id =>record.id,
      :commentable_type=> record.class.name,
      :comment =>comment_text )
    if record.class.name.eql?("TneInvoice")
      if comment.save
        object = record
        pdf_file_name = object.generate_invoice_pdf(object.view_by=='Detailed' ? true :false)
        pdf_file = File.read(pdf_file_name)
        create_document(pdf_file,'pdf',object,comment)
        excel_file = object.generate_invoice_xls(object.view_by=='Detailed' ? true :false)
        create_document(excel_file,'xls',object,comment)
      end
    end
    if record.instance_of?(Matter)
      send_notification_for_matter(record,true)
    end
  end

  #  Added by Pratik A J 29-06-2011 : To save document of different format.
  def create_document(file, file_type, object, comment, file_name=nil)
    if object.invoice_no.include?('/')
      file_obj=object.invoice_no.gsub('/','')
    else
      file_obj=object.invoice_no
    end
    filename = (file_name ? "#{file_name}.#{file_type}" : nil ) || "InvoiceNo_#{file_obj}_#{Time.zone.now.to_i}_New.#{file_type}"

    newfile=File.open("#{filename}", "w") {|f| f.write(file) }

    root_file=File.open("#{RAILS_ROOT}/#{filename}",'r')
    document={:name => "Test" ,:data=> root_file}
    document_home = {:document_attributes => document}
    document_home.merge!(:access_rights => 2, :created_by_user_id=>object.created_by_user_id,:company_id=>object.company_id,
      :mapable_id=>comment.id,:mapable_type=>'Comment', :owner_user_id=>object.owner_user_id)
    newdocument_home = comment.document_homes.new(document_home)
    newdocument = newdocument_home.documents.build(document.merge(:company_id=>object.company_id, :created_by_user_id=>object.created_by_user_id))
    newdocument_home.save
    if newdocument_home.save
      root_file.close
      File.delete("#{RAILS_ROOT}/#{filename}")
    end
  end

  def send_notification_for_matter(object,is_create)
    euid = User.current_user.verified_lawyer_id_by_secretary
    employee_user = User.current_user
    if euid
      employee_user = User.find(euid)
    end
    if is_create
      if object.employee_user_id == euid
        subject = "Lead Lawyer for New Matter: #{object.name}"
        body = "Dear #{object.user.first_name} #{object.user.last_name},
        This is a notification email is to inform you that you have successfully
        created Matter name: #{object.name} and you
        are the Lead lawyer.
        You created this matter on  #{Time.now.in_time_zone(object.user.time_zone)}"
      else
        subject = "Lead Lawyer for New Matter: #{object.name}"
        body = "Dear #{object.user.first_name} #{object.user.last_name},
        This is a notification email to inform you that you are responsible for
        Matter Name: #{object.name}.
        This Matter has been created  by #{employee_user.first_name}
        #{employee_user.last_name} on #{Time.now.in_time_zone(object.user.time_zone)}"
      end
      send_notification_to_email_to_user(object.user, subject, body)
    else
      unless(object.employee_user_id_was.to_i == object.employee_user_id.to_i)
        previous_lead = User.find_by_id(object.employee_user_id_was.to_i)
        subject = "Lead Lawyer for Matter name: #{object.name}"
        body = "Dear #{object.user.first_name} #{object.user.last_name},
        This is a notification email to inform you that you are responsible for
        Matter Name: #{object.name}.
        This Matter has been updated by #{previous_lead.first_name}
        #{previous_lead.last_name} on #{Time.now.in_time_zone(object.user.time_zone)}"
        send_notification_to_email_to_user(object.user, subject, body)
      end
    end
  end

  def before_destroy(object)
    if object.instance_of?(TneInvoice)
      Comment.create(:title=> 'Invoice Cancelled',
        :created_by_user_id=> User.current_user.id,
        :commentable_id => object.id,:commentable_type=> object.class.name,
        :comment => 'Invoice Cancelled' ,
        :company_id=> object.company_id )
    else      
      if(object.class.reflect_on_association(:comments))
        object.comments << Comment.new(:title=> object.class.human_name + ' Deactivated',
          :created_by_user_id=> User.current_user.id,
          :commentable_id => object.id,:commentable_type=> object.class.human_name,
          :comment => object.class.human_name + " Deactivated",
          :company_id=> object.company_id )
      end
    end
  end


  def before_update(object)
    cancelled_status = TneInvoiceStatus.find_by_lvalue_and_company_id('Cancelled', object.company_id).id
    if object.instance_of?(Contact)
      if object.deleted_at_changed? && object.deleted_at.nil? && !object.comment_added
        object.comments << Comment.new(:title=> 'Contact' + ' Activated',
          :created_by_user_id=>  User.current_user.id,
          :commentable_id => object.id,:commentable_type=> 'Contact',
          :comment => "Contact Activated",
          :company_id=> object.company_id )
        object.comment_added=true
      end
      if  !object.comment_added && (object.contact_stage_id_changed? && !object.contact_stage_id_was.eql?(nil))
        object.comments << Comment.new(:title=> 'Status Update',
          :created_by_user_id=>  User.current_user.id,
          :company_id=> object.company_id,
          :commentable_id => object.id,:commentable_type=> object.class,
          :comment =>"Contact updated from #{ContactStage.find_by_id(object.contact_stage_id_was).alvalue.try(:titleize)} to #{ContactStage.find_by_id(object.contact_stage_id).alvalue.try(:titleize)} reason being #{object.reason}" )
        object.comment_added=true
      end
    elsif object.instance_of?(Account)
      if object.deleted_at_changed? && object.deleted_at.nil?
        object.comments << Comment.new(:title=> 'Account' + ' Activated',
          :created_by_user_id=>  User.current_user.id,
          :commentable_id => object.id,:commentable_type=> 'Account',
          :comment => "Contact Activated",
          :company_id=> object.company_id )
      end
    elsif object.instance_of?(MatterBilling) 
      if (object.matter_billing_status_id == cancelled_status)
        Comment.create(:title=> 'Invoice Cancelled',
          :created_by_user_id=> User.current_user.id,
          :commentable_id => object.id,:commentable_type=> object.class.name,
          :comment => 'Invoice Cancelled' ,
          :company_id=> object.company_id )
      elsif (object.matter_billing_status_id_changed? && !object.matter_billing_status_id_was.eql?(nil))
        status_was = TneInvoiceStatus.find_by_id(object.matter_billing_status_id_was).alvalue.try(:titleize)
        currentstatus = TneInvoiceStatus.find_by_id(object.matter_billing_status_id)
        status_is = currentstatus.alvalue.try(:titleize)
        Comment.create(:title=> 'Status Updated',
          :created_by_user_id=>  User.current_user.id,
          :commentable_id => object.id,:commentable_type=> 'MatterBilling',
          :comment => "Invoice updated from #{status_was} to #{status_is} reason being #{object.remarks}",
          :company_id=> object.company_id)
      else
        Comment.create(:title=> 'Invoice Updated',
          :created_by_user_id=>  User.current_user.id,
          :commentable_id => object.id,:commentable_type=> 'MatterBilling',
          :comment => 'Invoice details updated',
          :company_id=> object.company_id)
      end
    elsif object.instance_of?(TneInvoice)
      if object.invoice_no.include?('/')
        file_obj=object.invoice_no.gsub('/','')
      else
        file_obj=object.invoice_no
      end
      status_was = TneInvoiceStatus.find_by_id(object.tne_invoice_status_id_was).alvalue.try(:titleize)
      currentstatus = TneInvoiceStatus.find_by_id(object.tne_invoice_status_id)
      status_is = currentstatus.alvalue.try(:titleize)
      save_comment = false
      
      unless(object.tne_invoice_status_id_changed?  || (object.tne_invoice_status_id==cancelled_status))       
        comment = Comment.new(:title=> 'Invoice Updated',
          :created_by_user_id=>  User.current_user.id,
          :commentable_id => object.id,:commentable_type=> 'TneInvoice',
          :comment => "Invoice details updated",
          :company_id=> object.company_id)
         
        filename = "InvoiceNo_#{file_obj}_#{Time.zone.now.to_i}_updated"       
        save_comment = true        
      end
      if (object.tne_invoice_status_id_changed? && !object.tne_invoice_status_id_was.eql?(nil) && !(object.tne_invoice_status_id==cancelled_status))
        comment = Comment.new(:title=> 'Status Updated',
          :created_by_user_id=>  User.current_user.id,
          :commentable_id => object.id,:commentable_type=> 'TneInvoice',
          :comment => "Invoice updated from #{status_was} to #{status_is} reason being #{object.status_reason}",
          :company_id=> object.company_id)
        save_comment = true
        filename = "InvoiceNo_#{file_obj}_#{Time.zone.now.to_i}_#{status_was}"
      end
      if save_comment && comment.save
        object.comments << comment
        pdf_file_name = object.generate_invoice_pdf(object.view_by=='Detailed' ? true :false)
        pdf_file = File.read(pdf_file_name)
        create_document(pdf_file,'pdf',object,comment,filename)
        excel_file = object.generate_invoice_xls(object.view_by=='Detailed' ? true :false)
        create_document(excel_file,'xls',object,comment,filename)
      end
    end
  end

end

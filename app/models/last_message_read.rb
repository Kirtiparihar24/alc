class LastMessageRead < ActiveRecord::Base
set_table_name :last_message_read
 
end


# == Schema Information
#
# Table name: last_message_read
#
#  id         :integer         not null, primary key
#  message    :string(255)
#  company_id :integer
#


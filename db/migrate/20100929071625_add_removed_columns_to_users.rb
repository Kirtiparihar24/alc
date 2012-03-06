class AddRemovedColumnsToUsers < ActiveRecord::Migration
  def self.up
    unless User.column_names.to_a.include?("security_question")
      add_column(:users,:security_question,:text)
    else  
      announce "Column security_question is already exist!"
    end
    
    unless User.column_names.to_a.include?("security_answer")
      add_column(:users,:security_answer,:text)
    else  
      announce "Column security_answer is already exist!"
    end    
          
  end

  def self.down
    if User.column_names.to_a.include?("security_question")
      remove_column(:users,:security_question)
    else  
      announce "Column security_question is not exist - already removed!"
    end
    
    if User.column_names.to_a.include?("security_answer")
      remove_column(:users,:security_answer)
    else  
      announce "Column security_answer is not exist - already removed!"
    end
  end
end

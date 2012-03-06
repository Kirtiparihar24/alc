class Repository < ActiveRecord::Base
  has_many :folders, :as => :mapable, :dependent => :destroy
end

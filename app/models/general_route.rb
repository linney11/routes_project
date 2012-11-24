class GeneralRoute< ActiveRecord::Base
  has_many :routes,:dependent => :destroy
  # attr_accessible :title, :body
  attr_accessible :name, :description
end

class Route < ActiveRecord::Base
  has_many :gps_samples, :dependent => :destroy
  # Set attributes as accessible for mass-assignment
  attr_accessible :name, :description , :general_route_id

end

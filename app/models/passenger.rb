class Passenger < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :route
  attr_accessible :timestamp, :count, :route_id
end

class GpsSample < ActiveRecord::Base
  has_one :nfc_sample
  # attr_accessible :title, :body
  attr_accessible :latitude, :longitude, :timestamp, :route_id
end

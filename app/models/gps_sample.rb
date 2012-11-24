class GpsSample < ActiveRecord::Base
  has_many :nfc_samples, :dependent => :destroy
  belongs_to :route
  # attr_accessible :title, :body
  attr_accessible :latitude, :longitude, :timestamp, :route_id
end

class NfcSample < ActiveRecord::Base
  has_one :survey
  belongs_to :gps_sample
  # attr_accessible :title, :body
  attr_accessible :message, :timestamp, :gps_sample_id
end

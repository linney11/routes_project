class NfcSample < ActiveRecord::Base
  has_one :survey
  # attr_accessible :title, :body
  attr_accessible :message, :timestamp, :gps_id
end

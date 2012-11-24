class NfcSample < ActiveRecord::Base
  has_many :surveys, :dependent => :destroy
  belongs_to :gps_sample
  # attr_accessible :title, :body
  attr_accessible :message, :timestamp, :gps_sample_id
end

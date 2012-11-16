class Survey < ActiveRecord::Base
  belongs_to :nfc_sample
  attr_accessible :answer, :timestamp, :nfc_sample_id
end

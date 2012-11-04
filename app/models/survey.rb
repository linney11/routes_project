class Survey < ActiveRecord::Base
  attr_accessible :answer, :timestamp, :nfc_id
end

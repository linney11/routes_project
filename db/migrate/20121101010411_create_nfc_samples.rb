class CreateNfcSamples < ActiveRecord::Migration
  def up
    create_table 'nfc_samples' do |t|
      t.string 'message'
      t.integer 'timestamp',:null => false, :limit => 8
      t.integer 'gps_sample_id'
    end
  end

  def down
    drop_table 'nfc_samples'
  end
end

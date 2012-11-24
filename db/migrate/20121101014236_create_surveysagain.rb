class CreateSurveysagain < ActiveRecord::Migration
  def up
    create_table 'surveys' do |t|
      t.string 'answer'
      t.integer 'timestamp',:null => false, :limit => 8
      t.integer 'nfc_id'
    end
  end

  def down
    drop_table 'surveys'
  end
end

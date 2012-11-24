class DroptableSurvey < ActiveRecord::Migration
  def up
    drop_table 'survey'
  end

  def down
  end
end

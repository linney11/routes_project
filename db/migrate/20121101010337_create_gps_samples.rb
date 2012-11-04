class CreateGpsSamples < ActiveRecord::Migration
  def up
    create_table 'gps_samples' do |t|
      t.float 'latitude', :null => false, :limit => 53
      t.float 'longitude', :null => false, :limit => 53
      t.integer 'timestamp',:null => false, :limit => 8
      t.integer 'route_id'
    end
  end

  def down
    drop_table 'gps_samples'
  end
end

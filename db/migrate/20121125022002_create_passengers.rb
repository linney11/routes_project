class CreatePassengers < ActiveRecord::Migration
  def up
    create_table 'passengers' do |t|
      t.integer 'timestamp',:null => false, :limit => 8
      t.integer 'count',:null => false, :limit => 8
      t.integer 'route_id'
    end
  end

  def down
    drop_table 'passengers'
  end
end

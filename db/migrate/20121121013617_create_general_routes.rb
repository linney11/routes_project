class CreateGeneralRoutes < ActiveRecord::Migration
  def up
    create_table 'general_routes' do |t|
      t.string 'name', :null => false
      t.string 'description'
    end
  end

  def down
    drop 'general_routes'
  end
end

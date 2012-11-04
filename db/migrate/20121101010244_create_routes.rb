class CreateRoutes < ActiveRecord::Migration
  def up
    create_table 'routes' do |t|
      t.string 'name', :null => false
      t.string 'description'
    end
  end

  def down
    drop 'routes'
  end
end

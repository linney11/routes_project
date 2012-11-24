class AddGeneralRouteIdToRoutes < ActiveRecord::Migration
  def change
      add_column :routes, :general_route_id, :integer
  end
end

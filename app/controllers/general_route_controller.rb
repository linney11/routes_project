class GeneralRouteController < ApplicationController

  def index
    # get all locations in the table locations
    @general_routes = GeneralRoute.all

  end

  def new
    # default: render ’new’ template
  end

  def create
    # create a new instance variable called @location that holds a Location object built from the data the user submitted
    @general_route= GeneralRoute.new(params[:general_route])

    # if the object saves correctly to the database
    if @general_route.save
      # redirect the user to index
      redirect_to general_route_index_path
    else
      # redirect the user to the new method
      render action: 'new'
    end
  end

  def edit
    # find only the location that has the id defined in params[:id]
    @general_route = GeneralRoute.find(params[:id])
  end

  def update
    # find only the location that has the id defined in params[:id]
    @general_route = GeneralRoute.find(params[:id])

    # if the object saves correctly to the database
    if @general_route.update_attributes(params[:general_route])
      # redirect the user to index
      redirect_to general_route_index_path
    else
      # redirect the user to the edit method
      render action: 'edit'
    end
  end

  def destroy
    # find only the location that has the id defined in params[:id]
    @general_route = GeneralRoute.find(params[:id])

    # delete the location object and any child objects associated with it
    @general_route.destroy

    # redirect the user to index
    redirect_to general_route_index_path
  end

  def destroy_all
    # delete all location objects and any child objects associated with them
    GeneralRoute.destroy_all

    # redirect the user to index
    redirect_to general_route_index_path
  end


  def show
    @general_route = GeneralRoute.find(params[:id])
    @routes=Route.find_all_by_general_route_id(params[:id])


  end


end




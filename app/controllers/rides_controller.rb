class RidesController < ApplicationController
  before_action :set_ride, only: %i[ show update destroy ]

  # must be string to match 'params[:ride].keys'
  REQUIRED_PARAMS = ['driver_id', 'start_address_id', 'dest_address_id']

  # GET driver/:driver_id/rides, this replaces normal rides index page
  def index
    # FUTURE: authorization permissions check
    # ./rides or non-positive :driver_id returns 422 - could be before_action
    return if invalid_param?(:driver_id)

    # get driver's rides, sort by score, paginate
    @rides = Ride.where(driver_id: params[:driver_id]).ran.order('ride_score desc')
    pagy, @rides = pagy(@rides)

    render json: { rides: @rides, pagination: pagy_output(pagy) }
  end

  # GET /rides/1
  def show
    render json: @ride
  end

  # POST /rides
  def create
    # don't process anything if required params are missing (different from update, where they are optional)
    if (REQUIRED_PARAMS - params[:ride].keys).present?
      render json: { error: "error in create ride: missing params: #{(REQUIRED_PARAMS - params[:ride].keys).join(', ')}" }, status: :unprocessable_entity
      return
    end

    @ride = Ride.new(ride_params)
    @ride.handle_drive_data(ride_params)

    if @ride.save
      render json: @ride, status: :created, location: @ride
    else
      render json: @ride.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /rides/1
  def update
    # FUTURE: logic around when this is allowed
    if @ride.start_address_id != ride_params[:start_address_id] ||
         @ride.dest_address_id != ride_params[:dest_address_id] ||
         @ride.driver_id != ride_params[:driver_id]
      # could optimize: determine if just ride or commute or both to update.
      # NOTE: currently addresses are the only params permitted, so it should always update from API/existing.
      @ride.handle_drive_data(ride_params)
    end

    if @ride.update(ride_params)
      render json: @ride
    else
      render json: @ride.errors, status: :unprocessable_entity
    end
  end

  # DELETE /rides/1
  def destroy
    @ride.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ride
      @ride = Ride.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ride_params
      params.require(:ride).permit(:driver_id, :start_address_id, :dest_address_id)
    end

    def invalid_param?(p)
      return false if params[p].to_i > 0

      render json: { error: 'Unprocessable Entity', message: "Invalid value for #{p}" }, status: :unprocessable_entity
      return true
    end
end

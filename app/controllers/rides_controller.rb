class RidesController < ApplicationController
  before_action :set_ride, only: %i[ show update destroy ]

  # GET driver/:driver_id/rides, this replaces normal rides index page
  def index
    # FUTURE: authorization permissions check
    # ./rides or non-positive number returns 422 - could be before_action
    return if invalid_param(:driver_id)

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
    @ride = Ride.new(ride_params)

    # FUTURE: allow parsing of given address, instead of just ids
    existing_ride = Ride.where(start_address_id: params[:start_address_id],
        dest_address_id: params[:dest_address_id]).\
        where('ride_earnings is not null').last

    # If we have ride to/from same place, use those previously-gathered values
    if existing_ride.present?
      @ride.commute_dist = existing_ride.commute_dist
      @ride.commute_duration = existing_ride.commute_duration
      @ride.ride_dist = existing_ride.ride_dist
      @ride.ride_duration = existing_ride.ride_duration
      @ride.ride_earnings = existing_ride.ride_earnings
      @ride.ride_score = existing_ride.ride_score
    else
      # If it's a new to/from pair, pull from Directions API
      @ride.api_directions
    end

    if @ride.save
      render json: @ride, status: :created, location: @ride
    else
      render json: @ride.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /rides/1
  def update
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
      params.require(:ride).permit(:start_address_id, :dest_address_id, :commute_dist, :commute_duration, :ride_dist, :ride_duration, :ride_earnings)
    end

    def invalid_param(p)
      return if params[p].to_i > 0

      render json: { error: 'Unprocessable Entity', message: "Invalid value for #{p}" }, status: :unprocessable_entity
      return true
    end
end

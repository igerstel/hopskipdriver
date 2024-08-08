class DriversController < ApplicationController
  before_action :set_driver, only: %i[ show update destroy ]

  # GET /drivers
  def index
    @drivers = Driver.all

    render json: @drivers
  end

  # GET /drivers/1
  def show
    render json: @driver
  end

  # POST /drivers
  def create
    # requires params[:address_id]
    @driver = Driver.new(driver_params)

    if @driver.save
      render json: @driver, status: :created, location: @driver
    else
      render json: @driver.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /drivers/1
  def update
    # FUTURE: do we need a history to preserve archived commute data?
    if @driver.update(driver_params)
      render json: @driver
    else
      render json: @driver.errors, status: :unprocessable_entity
    end
  end

  # DELETE /drivers/1
  def destroy
    @driver.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_driver
      @driver = Driver.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def driver_params
      params.require(:driver).permit(:home_address_id)
    end
end

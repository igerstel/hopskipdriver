require 'test_helper'
require 'mocha/minitest'

class RideTest < ActiveSupport::TestCase
  def setup
    @ride = rides(:one)
    @addr1 = addresses(:one)
    @addr2 = addresses(:two)
    @addr3 = addresses(:three)
    @driver = drivers(:one)
  end

  # column validations
  test 'should be valid' do
    assert @ride.valid?
  end

  test 'should require driver_id' do
    @ride.driver_id = nil
    assert_not @ride.valid?
  end

  test 'should require start_address_id' do
    @ride.start_address_id = nil
    assert_not @ride.valid?
  end

  test 'should require dest_address_id' do
    @ride.dest_address_id = nil
    assert_not @ride.valid?
  end

  test 'scope :ran should return rides with non-null ride_score' do
    ran_rides = Ride.ran
    assert_not_empty ran_rides
    assert ran_rides.all? { |ride| ride.ride_score.present? }
  end

  # handle_drive_data
  test 'handle_drive_data should fetch data from API' do
    # if no rides have 'ran', use Directions API
    Ride.update_all(ride_score: nil)
    Ride.any_instance.expects(:api_directions).once
    Ride.any_instance.expects(:drive_data_from_existing).never

    new_ride = Ride.new
    new_ride.handle_drive_data({ start_address_id: @addr1.id, dest_address_id: @addr2.id })
  end

  test 'handle_drive_data should fetch data from existing ride' do
    # if the addresses are from existing ride, use those
    Ride.any_instance.expects(:api_directions).never
    Ride.any_instance.expects(:drive_data_from_existing).once

    new_ride = Ride.new()
    new_ride.handle_drive_data({
      start_address_id: @ride.start_address_id,
      dest_address_id: @ride.dest_address_id
    })
  end


end



# test 'api_directions should populate ride data from DirectionsApi' do
#   ride = rides(:valid_ride)
#   DirectionsApi.stub(:get_directions, { distance: 10, duration: 20 }) do
#     ride.api_directions
#     assert_equal 10, ride.commute_dist
#     assert_equal 20, ride.commute_duration
#   end
# end

# test 'earnings should calculate correct earnings' do
#   ride = rides(:valid_ride)
#   ride.ride_dist = 15
#   ride.ride_duration = 30
#   assert_equal 18.75, ride.earnings
# end

# test 'score should calculate correct score' do
#   ride = rides(:valid_ride)
#   ride.ride_earnings = 50
#   ride.commute_duration = 20
#   ride.ride_duration = 30
#   assert_equal 1.25, ride.score
# end

# test 'drive_data_from_existing should update drive data from existing ride' do
#   existing_ride = rides(:valid_ride)
#   new_ride = Ride.new
#   new_ride.drive_data_from_existing(existing_ride)
#   assert_equal existing_ride.commute_dist, new_ride.commute_dist
#   # Repeat for other DRIVE_DATA attributes
# end







# require 'test_helper'

# class RideTest < ActiveSupport::TestCase
#   setup do
#     @driver = drivers(:one)
#     @start_address = addresses(:one)
#     @dest_address = addresses(:two)
#     @existing_ride = rides(:one)
#     @ride = Ride.new(driver: @driver, start_address: @start_address, dest_address: @dest_address)
#   end

#   test "should be valid with valid attributes" do
#     assert @ride.valid?
#   end

#   test "should not be valid without a driver_id" do
#     @ride.driver_id = nil
#     assert_not @ride.valid?
#     assert_includes @ride.errors[:driver_id], "can't be blank"
#   end

#   test "should not be valid without a start_address_id" do
#     @ride.start_address_id = nil
#     assert_not @ride.valid?
#     assert_includes @ride.errors[:start_address_id], "can't be blank"
#   end

#   test "should not be valid without a dest_address_id" do
#     @ride.dest_address_id = nil
#     assert_not @ride.valid?
#     assert_includes @ride.errors[:dest_address_id], "can't be blank"
#   end

#   test "ran scope should return only rides with ride_score not null" do
#     ran_rides = Ride.ran
#     assert_includes ran_rides, @existing_ride
#     assert_not_includes ran_rides, rides(:two) # assuming rides(:two) has a nil ride_score
#   end


#   test "should call api_directions if no existing ride" do
#     Ride.stub :where, [] do
#       @ride.stub :api_directions, true do
#         @ride.handle_drive_data(start_address_id: @start_address.id, dest_address_id: @dest_address.id)
#         assert @ride.api_directions_called
#       end
#     end
#   end

#   test "should calculate correct earnings" do
#     @ride.ride_dist = 10
#     @ride.ride_duration = 1.5
#     assert_equal 14.05, @ride.earnings
#   end

#   test "should calculate correct score" do
#     @ride.ride_earnings = 20
#     @ride.commute_duration = 0.5
#     @ride.ride_duration = 1.0
#     assert_equal 13.333, @ride.score
#   end

#   test "should copy drive data from existing ride" do
#     @ride.drive_data_from_existing(@existing_ride)
#     assert_equal @existing_ride.commute_dist, @ride.commute_dist
#     assert_equal @existing_ride.ride_earnings, @ride.ride_earnings
#   end
# end

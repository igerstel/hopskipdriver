require "test_helper"

class RidesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ride = rides(:one)
  end

  test "should get index" do
    get rides_url, as: :json
    assert_response :success
  end

  test "should create ride" do
    assert_difference("Ride.count") do
      post rides_url, params: { ride: { commute_dist: @ride.commute_dist, commute_duration: @ride.commute_duration, dest_address_id: @ride.dest_address_id, ride_dist: @ride.ride_dist, ride_duration: @ride.ride_duration, ride_earnings: @ride.ride_earnings, start_address_id: @ride.start_address_id } }, as: :json
    end

    assert_response :created
  end

  test "should show ride" do
    get ride_url(@ride), as: :json
    assert_response :success
  end

  test "should update ride" do
    patch ride_url(@ride), params: { ride: { commute_dist: @ride.commute_dist, commute_duration: @ride.commute_duration, dest_address_id: @ride.dest_address_id, ride_dist: @ride.ride_dist, ride_duration: @ride.ride_duration, ride_earnings: @ride.ride_earnings, start_address_id: @ride.start_address_id } }, as: :json
    assert_response :success
  end

  test "should destroy ride" do
    assert_difference("Ride.count", -1) do
      delete ride_url(@ride), as: :json
    end

    assert_response :no_content
  end
end

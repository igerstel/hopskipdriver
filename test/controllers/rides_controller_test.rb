require "test_helper"
require 'minitest/autorun'
require 'mocha/minitest'

class RidesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ride = rides(:one)
    @directions_api = DirectionsApi.new

    @ride_params = { ride: {
        driver_id: @ride.driver_id,
        start_address_id: @ride.start_address_id,
        dest_address_id: @ride.dest_address_id,
    } }

    stub_request(:get, 'https://maps.googleapis.com/maps/api/directions/json')
      .to_return(status: 200, body: '{"key": "value"}', headers: {})
  end

  test "should return 422 with no/bad driver_id" do
    get rides_url, as: :json
    assert_equal '{"error":"Unprocessable Entity","message":"Invalid value for driver_id"}', @response.body
    assert_response :unprocessable_entity

    get rides_url, params: { driver_id: 0 }
    assert_equal '{"error":"Unprocessable Entity","message":"Invalid value for driver_id"}', @response.body
    assert_response :unprocessable_entity
  end

  test "should get index" do
    get rides_url, params: { driver_id: @ride.driver_id }
    assert_response :success
  end

  test "should not create ride when missing params" do
    assert_no_difference("Ride.count") do
      post rides_url, params: { ride: {
          driver_id: @ride.driver_id,
          dest_address_id: @ride.dest_address_id,
      } }, as: :json
    end

    assert_equal '{"error":"error in create ride: missing params: start_address_id"}', @response.body
    assert_response :unprocessable_entity
  end

  test "should return error when it cannot save" do
    Ride.any_instance.stubs(:save).returns(false)
    Ride.any_instance.stubs(:errors).returns({ error: 'borked' })

    assert_no_difference("Ride.count") do
      post rides_url, params: @ride_params, as: :json
    end

    assert_equal '{"error":"borked"}', @response.body
    assert_response :unprocessable_entity
  end

  test "should create ride from (webmock) API call" do
    # NOTE: not testing ride.api_directions here, so we don't check
    # time/distance/earnings/score values (nil in this case)

    # remove all duplicate records
    Ride.where(start_address_id: @ride.start_address_id,
        dest_address_id: @ride.dest_address_id).delete_all

    # mocha gem for cleaner mocks/stubs
    Ride.any_instance.expects(:api_directions).once
    Ride.any_instance.expects(:drive_data_from_existing).never

    assert_difference("Ride.count", 1) do
      post rides_url, params: @ride_params, as: :json
    end

    assert_response :created
  end

  test "should create ride from existing record" do
    # NOTE: not testing ride.api_directions here, so we don't check
    # time/distance/earnings/score values (nil in this case)

    # mocha gem for cleaner mocks/stubs
    Ride.any_instance.expects(:api_directions).never
    Ride.any_instance.expects(:drive_data_from_existing).once

    assert_difference("Ride.count", 1) do
      post rides_url, params: @ride_params, as: :json
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

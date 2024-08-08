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

  # INDEX
  test "should return 422 with no/bad driver_id" do
    get rides_url, as: :json
    assert_equal '{"error":"Unprocessable Entity","message":"Invalid value for driver_id"}', @response.body
    assert_response :unprocessable_entity

    get rides_url, params: { driver_id: 0 }
    assert_equal '{"error":"Unprocessable Entity","message":"Invalid value for driver_id"}', @response.body
    assert_response :unprocessable_entity
  end

  test "should get index and handle pagination (rides key)" do
    Ride.delete_all
    get rides_url, params: { driver_id: @ride.driver_id }

    # NOTE: scores here do not represent drive details; they are just
    # for sorting verification
    36.times do |t|
      ride = @ride.dup
      ride.ride_score = rand(255)
      ride.save
    end

    # default is 10 items per page, there are now 36 records
    # page 1
    get rides_url, params: { driver_id: @ride.driver_id }
    rides_json = JSON.parse(@response.body)['rides']

    # Check for the presence of specific keys, items on page, and sorting
    assert_response :success
    assert rides_json.count == 10
    assert rides_json[0].key?('id')
    assert rides_json[0].key?('driver_id')
    assert rides_json[0].key?('start_address_id')
    assert rides_json[0].key?('dest_address_id')
    assert rides_json[0].key?('commute_dist')
    assert rides_json[0].key?('commute_duration')
    assert rides_json[0].key?('ride_dist')
    assert rides_json[0].key?('ride_duration')
    assert rides_json[0].key?('ride_earnings')
    assert rides_json[0].key?('ride_score')
    assert rides_json[0].key?('created_at')
    assert rides_json[0].key?('updated_at')
    rides_json[0..8].each_with_index do |r, i|
      assert r['ride_score'] <= rides_json[i]['ride_score']
    end

    # page 4
    get rides_url, params: { driver_id: @ride.driver_id, page: 4 }
    rides_json = JSON.parse(@response.body)['rides']

    # Check not-full last page, and sorting
    assert_response :success
    assert rides_json.count == 6
    rides_json[0..5].each_with_index do |r, i|
      assert r['ride_score'] <= rides_json[i]['ride_score']
    end

    # beyond final page defaults to final page
    get rides_url, params: { driver_id: @ride.driver_id, page: 999 }
    rides_json = JSON.parse(@response.body)['rides']

    # Check not-full last page, and sorting
    assert_response :success
    assert rides_json.count == 6
  end

  test "should get index and handle pagination (pagination key)" do
    page_output = {
      'page' => 1,
      'per_page' => 10,
      'count' => 36,
      'pages' => 4,
    }

    Ride.delete_all
    get rides_url, params: { driver_id: @ride.driver_id }

    # NOTE: scores here do not represent drive details; they are just
    # for sorting verification
    36.times do |t|
      ride = @ride.dup
      ride.ride_score = rand(255)
      ride.save
    end

    # default is 10 items per page, there are now 36 records
    # page 1
    get rides_url, params: { driver_id: @ride.driver_id }
    page_json = JSON.parse(@response.body)['pagination']

    # Check for correct page and pagination values
    assert_response :success
    assert page_json == page_output

    # page 4
    page_output['page'] = 4
    get rides_url, params: { driver_id: @ride.driver_id, page: 4 }
    page_json = JSON.parse(@response.body)['pagination']

    # Check for correct page and pagination values
    assert_response :success
    assert (page_json == page_output)

    # beyond final page defaults to final page
    page_output['page'] = 4
    get rides_url, params: { driver_id: @ride.driver_id, page: 999 }
    page_json = JSON.parse(@response.body)['pagination']

    # Check for correct page and pagination values
    assert_response :success
    assert page_json == page_output
  end

  # CREATE
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

  # SHOW
  test "should show ride" do
    get ride_url(@ride), as: :json
    assert_response :success
  end

  # UPDATE
  test "should update ride" do
    patch ride_url(@ride), params: { ride: { commute_dist: @ride.commute_dist, commute_duration: @ride.commute_duration, dest_address_id: @ride.dest_address_id, ride_dist: @ride.ride_dist, ride_duration: @ride.ride_duration, ride_earnings: @ride.ride_earnings, start_address_id: @ride.start_address_id } }, as: :json
    assert_response :success
  end

  # DELETE
  test "should destroy ride" do
    assert_difference("Ride.count", -1) do
      delete ride_url(@ride), as: :json
    end

    assert_response :no_content
  end

  # private method 'invalid_param?(p)' tested in show calls
end

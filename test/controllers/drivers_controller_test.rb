require "test_helper"

class DriversControllerTest < ActionDispatch::IntegrationTest
  setup do
    @driver = drivers(:one)
  end

  test "should get index" do
    get drivers_url, as: :json
    assert_response :success
  end

  test "should create driver when there is an address" do
    addr = addresses(:one)
    @driver.home_address = addr

    assert_difference("Driver.count", 1) do
      post drivers_url, params: { driver: { home_address_id: @driver.home_address_id } }, as: :json
    end

    assert_response :created
  end

  test "should not create driver when there is no address" do
    post drivers_url, params: { driver: { home_address_id: nil } }, as: :json
    assert_equal '{"home_address":["must exist"],"home_address_id":["can\'t be blank"]}', @response.body
    assert_response :unprocessable_entity
  end

  test "should show driver" do
    get driver_url(@driver), as: :json
    assert_response :success
  end

  test "should update driver" do
    patch driver_url(@driver), params: { driver: { home_address_id: @driver.home_address_id } }, as: :json
    assert_response :success
  end

  test "should destroy driver" do
    assert_difference("Driver.count", -1) do
      delete driver_url(@driver), as: :json
    end

    assert_response :no_content
  end
end

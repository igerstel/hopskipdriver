require 'rails_helper'

RSpec.describe "Drivers", type: :request do
  before(:each) do
    @driver = create(:driver)  # Assuming you're using FactoryBot for fixtures
  end

  describe "GET /index" do
    it "returns http success" do
      get drivers_url, as: :json
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /create" do
    context "when there is an address" do
      it "creates a new driver" do
        addr = create(:address)
        @driver.home_address = addr

        expect {
          post drivers_url, params: { driver: { home_address_id: @driver.home_address_id } }, as: :json
        }.to change(Driver, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context "when there is no address" do
      it "does not create a new driver" do
        expect {
          post drivers_url, params: { driver: { home_address_id: nil } }, as: :json
        }.to_not change(Driver, :count)

        expect(response.body).to eq('{"home_address":["must exist"],"home_address_id":["can\'t be blank"]}')
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get driver_url(@driver), as: :json
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /update" do
    it "updates the driver" do
      patch driver_url(@driver), params: { driver: { home_address_id: @driver.home_address_id } }, as: :json
      expect(response).to have_http_status(:success)
    end
  end

  describe "DELETE /destroy" do
    it "destroys the driver" do
      expect {
        delete driver_url(@driver), as: :json
      }.to change(Driver, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end

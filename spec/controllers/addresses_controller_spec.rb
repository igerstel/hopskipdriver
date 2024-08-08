require 'rails_helper'

RSpec.describe "Addresses", type: :request do
  before(:each) do
    @address = create(:address)
  end

  describe "GET /index" do
    it "returns http success" do
      get addresses_url, as: :json
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /create" do
    it "creates a new address" do
      expect {
        post addresses_url, params: { address: { city: @address.city, state: @address.state, street: @address.street, zip: @address.zip } }, as: :json
      }.to change(Address, :count).by(1)
      expect(response).to have_http_status(:created)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get address_url(@address), as: :json
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /update" do
    it "updates the address" do
      patch address_url(@address), params: { address: { city: @address.city, state: @address.state, street: @address.street, zip: @address.zip } }, as: :json
      expect(response).to have_http_status(:success)
    end
  end

  describe "DELETE /destroy" do
    it "destroys the address" do
      expect {
        delete address_url(@address), as: :json
      }.to change(Address, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end

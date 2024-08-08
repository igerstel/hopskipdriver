require 'rails_helper'
require 'webmock/rspec'

RSpec.describe "Rides", type: :request do
  before(:each) do
    @ride = create(:ride)
    @ride_params = {
      ride: {
        driver_id: @ride.driver_id,
        start_address_id: @ride.start_address_id,
        dest_address_id: @ride.dest_address_id
      }
    }
  end

  describe "GET /index" do
    it "returns 422 with no/bad driver_id" do
      get rides_url, as: :json
      expect(response.body).to eq('{"error":"Unprocessable Entity","message":"Invalid value for driver_id"}')
      expect(response).to have_http_status(:unprocessable_entity)

      get rides_url, params: { driver_id: 0 }
      expect(response.body).to eq('{"error":"Unprocessable Entity","message":"Invalid value for driver_id"}')
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "handles pagination (rides key)" do
      Ride.delete_all
      get rides_url, params: { driver_id: @ride.driver_id }

      # NOTE: scores here do not represent drive details; they are just
      # for sorting verification
      36.times do
        ride = @ride.dup
        ride.ride_score = rand(255)
        ride.save
      end

      # default is 10 items per page, there are now 36 records
      # page 1
      get rides_url, params: { driver_id: @ride.driver_id }
      rides_json = JSON.parse(response.body)['rides']

      expect(response).to have_http_status(:success)
      expect(rides_json.count).to eq(10)

      # Check for the presence of specific keys, items on page, and sorting
      %w[id driver_id start_address_id dest_address_id commute_dist commute_duration ride_dist ride_duration ride_earnings ride_score created_at updated_at].each do |key|
        expect(rides_json.first).to have_key(key)
      end
      rides_json[0..9].each_with_index do |r, i|
        assert r['ride_score'] <= rides_json[i]['ride_score']
      end

      # page 4
      get rides_url, params: { driver_id: @ride.driver_id, page: 4 }
      rides_json = JSON.parse(response.body)['rides']

      # Check not-full last page, and sorting
      expect(response).to have_http_status(:success)
      expect(rides_json.count).to eq(6)
      rides_json[0..5].each_with_index do |r, i|
        expect(r['ride_score']).to be >= rides_json[i]['ride_score']
      end

      # beyond final page defaults to final page
      get rides_url, params: { driver_id: @ride.driver_id, page: 999 }
      rides_json = JSON.parse(response.body)['rides']

      # Check not-full last page, and sorting
      expect(response).to have_http_status(:success)
      expect(rides_json.count).to eq(6)
      rides_json[0..5].each_with_index do |r, i|
        expect(r['ride_score']).to be >= rides_json[i]['ride_score']
      end
    end

    it "handles pagination (pagination key)" do
      page_output = {
        'page' => 1,
        'per_page' => 10,
        'count' => 36,
        'pages' => 4
      }

      Ride.delete_all
      get rides_url, params: { driver_id: @ride.driver_id }

      # NOTE: scores here do not represent drive details; they are just
      # for sorting verification
      36.times do
        ride = @ride.dup
        ride.ride_score = rand(255)
        ride.save
      end

      # default is 10 items per page, there are now 36 records
      # page 1
      get rides_url, params: { driver_id: @ride.driver_id }
      page_json = JSON.parse(response.body)['pagination']

      # Check for correct page and pagination values
      expect(response).to have_http_status(:success)
      expect(page_json).to eq(page_output)

      # page 4
      page_output['page'] = 4
      get rides_url, params: { driver_id: @ride.driver_id, page: 4 }
      page_json = JSON.parse(response.body)['pagination']

      # Check for correct page and pagination values
      expect(response).to have_http_status(:success)
      expect(page_json).to eq(page_output)

      # beyond final page defaults to final page
      page_output['page'] = 4
      get rides_url, params: { driver_id: @ride.driver_id, page: 999 }
      page_json = JSON.parse(response.body)['pagination']

      # Check for correct page and pagination values
      expect(response).to have_http_status(:success)
      expect(page_json).to eq(page_output)
    end
  end

  describe "POST /create" do
    it "returns error when missing params" do
      expect {
        post rides_url, params: { ride: { driver_id: @ride.driver_id, dest_address_id: @ride.dest_address_id } }, as: :json
      }.to_not change(Ride, :count)

      expect(response.body).to eq('{"error":"error in create ride: missing params: start_address_id"}')
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns error when it cannot save" do
      allow_any_instance_of(Ride).to receive(:save).and_return(false)
      allow_any_instance_of(Ride).to receive(:errors).and_return({ error: 'borked' })

      expect {
        post rides_url, params: @ride_params, as: :json
      }.to_not change(Ride, :count)

      expect(response.body).to eq('{"error":"borked"}')
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "creates ride from (webmock) API call" do
      # NOTE: not testing ride.api_directions here, so we don't check
      # time/distance/earnings/score values (nil in this case)

      # remove all duplicate records
      Ride.where(start_address_id: @ride.start_address_id, dest_address_id: @ride.dest_address_id).delete_all

      expect_any_instance_of(Ride).to receive(:api_directions).once
      expect_any_instance_of(Ride).to_not receive(:drive_data_from_existing)

      expect {
        post rides_url, params: @ride_params, as: :json
      }.to change(Ride, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "creates ride from existing record" do
      # NOTE: not testing ride.api_directions here, so we don't check
      # time/distance/earnings/score values (nil in this case)

      expect_any_instance_of(Ride).to_not receive(:api_directions)
      expect_any_instance_of(Ride).to receive(:drive_data_from_existing).once

      expect {
        post rides_url, params: @ride_params, as: :json
      }.to change(Ride, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get ride_url(@ride), as: :json
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /update" do
    it "updates ride with API when an id changes" do
      expect_any_instance_of(Ride).to receive(:handle_drive_data).once

      patch ride_url(@ride), params: { ride: { dest_address_id: @ride.dest_address_id, start_address_id: @ride.start_address_id } }, as: :json
      expect(response).to have_http_status(:success)
    end
  end

  describe "DELETE /destroy" do
    it "destroys the ride" do
      expect {
        delete ride_url(@ride), as: :json
      }.to change(Ride, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end

  # private method 'invalid_param?(p)' tested in show calls
end

require 'rails_helper'
require 'rest-client'
require 'webmock/rspec'

RSpec.describe DirectionsApi, type: :service do
  let(:start_addr) { create(:address) }
  let(:dest_addr) { create(:address) }
  let(:invalid_addr) { nil }

  describe 'get_directions' do
    it 'when start or destination address is blank or the same' do
      result = DirectionsApi.get_directions(invalid_addr, dest_addr)
      expect(result).to eq({ error: "There is a problem with the addresses" })

      result = DirectionsApi.get_directions(start_addr, invalid_addr)
      expect(result).to eq({ error: "There is a problem with the addresses" })

      result = DirectionsApi.get_directions(start_addr, start_addr)
      expect(result).to eq({ error: "There is a problem with the addresses" })
    end

    it 'returns an error when API raises an exception' do
      allow(RestClient).to receive(:get).and_raise(RestClient::ExceptionWithResponse.new(double(body: "API error")))
      result = DirectionsApi.get_directions(start_addr, dest_addr)
      expect(result).to eq({ error: 'An error occurred: API error' })
    end

    it 'returns an error when the API response status is not OK' do
      allow(RestClient).to receive(:get).and_return(JSON({ status: 'bad', error_message: 'oh no' }))
      result = DirectionsApi.get_directions(start_addr, dest_addr)
      expect(result).to eq({ error: 'Error retrieving data: oh no' })
    end

    context 'when API returns a valid response' do
      let(:api_response) do
        {
          'status' => 'OK',
          'routes' => [{
              'legs' => [{
                  'distance' => { 'text' => '10 mi', 'value' => 16093 },
                  'duration' => { 'text' => '20 mins', 'value' => 1200 }
              }]
          }]
        }
      end

      it 'returns distance and duration when valid' do
        allow(RestClient).to receive(:get).and_return(api_response.to_json)
        result = DirectionsApi.get_directions(start_addr, dest_addr)
        expect(result).to eq({ distance: 10.0, duration: 0.3333333333333333 })
      end

      it 'returns an error when time exceeds maximum allowed' do
        api_response['routes'][0]['legs'][0]['duration']['value'] = (Ride::MAX_TIME*DirectionsApi::SEC_TO_HR)+1
        allow(RestClient).to receive(:get).and_return(api_response.to_json)

        result = DirectionsApi.get_directions(start_addr, dest_addr)
        expect(result).to eq({ error: "Time or distance is too large for this trip" })
      end

      it 'returns an error when distance exceeds maximum allowed' do
        api_response['routes'][0]['legs'][0]['distance']['text'] = "#{Ride::MAX_DIST+1} mi"
        allow(RestClient).to receive(:get).and_return(api_response.to_json)

        result = DirectionsApi.get_directions(start_addr, dest_addr)
        expect(result).to eq({ error: "Time or distance is too large for this trip" })
      end
    end
  end

  describe 'model_to_address' do
    # all columns are required for Address to save
    it 'converts an Address model to a string' do
      address_string = DirectionsApi.model_to_address(start_addr)
      expected_string = "#{start_addr.street},#{start_addr.city},#{start_addr.state},#{start_addr.zip}"
      expect(address_string).to eq(expected_string)
    end
  end

  describe 'travel_compare' do
    let(:json_routes) do
      [
        { 'legs' => [
          { 'distance' => { 'text' => '10 mi', 'value' => 16093 } },
          { 'distance' => { 'text' => '5 mi', 'value' => 8047 } }
        ]},
        { 'legs' => [
          { 'distance' => { 'text' => '20 mi', 'value' => 32186 } }
        ]}
      ]
    end

    it 'compiles a flat set values from array of routes->legs' do
      result = DirectionsApi.travel_compare(json_routes, 'distance')
      expect(result).to eq([{ 'text' => '10 mi', 'value' => 16093 }, { 'text' => '5 mi', 'value' => 8047 }, { 'text' => '20 mi', 'value' => 32186 }])
    end

    it 'handles empty set' do
      result = DirectionsApi.travel_compare([], 'distance')
      expect(result).to be_empty
    end
  end

  describe 'min_travel_dist' do
    let(:json_routes) do
      [
        { 'legs' => [
            { 'distance' => { 'text' => '10 mi', 'value' => 16093 } },
            { 'distance' => { 'text' => '5 mi', 'value' => 8047 } }
        ]}
      ]
    end

    it 'returns the minimum travel distance' do
      result = DirectionsApi.min_travel_dist(json_routes)
      expect(result).to eq(5.0)
    end

    it 'returns an error if no distance found' do
      result = DirectionsApi.min_travel_dist([])
      expect(result).to eq({ error: "No distance found for this trip!" })

      json_routes[0]['legs'][0]['distance'] = {}
      json_routes[0]['legs'][1]['distance'] = {}
      result = DirectionsApi.min_travel_dist(json_routes)
      expect(result).to eq({ error: "No distance found for this trip!" })
    end
  end

  describe 'min_dist' do
    let(:distances) do
      [
        { 'text' => '10 mi' },
        { 'text' => '5280 ft' }  # 1 mi
      ]
    end

    it 'returns the minimum distance in miles' do
      result = DirectionsApi.min_dist(distances)
      expect(result).to eq(1.0)
    end
  end

  describe 'min_travel_time' do
    let(:json_routes) do
      [
        { 'legs' => [
          { 'duration' => { 'value' => 600 } },
          { 'duration' => { 'value' => 300 } }
        ]}
      ]
    end

    it 'returns the minimum travel time' do
      result = DirectionsApi.min_travel_time(json_routes)
      expect(result).to eq(0.08333333333333333)
    end

    it 'returns an error if no travel time found' do
      result = DirectionsApi.min_travel_time([])
      expect(result).to eq({ error: "No travel time found for this trip!" })

      json_routes[0]['legs'][0]['duration'] = {}
      json_routes[0]['legs'][1]['duration'] = {}
      result = DirectionsApi.min_travel_time(json_routes)
      expect(result).to eq({ error: "No travel time found for this trip!" })
    end
  end

  describe 'min_time' do
    let(:durations) do
      [
        { 'text' => '10 mins', 'value' => 600 },
        { 'text' => '5 mins', 'value' => 300 }
      ]
    end

    it 'returns the minimum time in hours' do
      result = DirectionsApi.min_time(durations)
      expect(result).to eq(0.08333333333333333)
    end
  end
end

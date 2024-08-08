require 'rails_helper'

RSpec.describe Ride, type: :model do
  before(:each) do
    @addr1 = create(:address)
    @addr2 = create(:address)
    @addr3 = create(:address)
    @driver = create(:driver, home_address: @addr3)
    @ride = create(:ride, driver: @driver, start_address: @addr1, dest_address: @addr2)
  end

  describe 'column validations and scopes' do
    it 'should be valid' do
      expect(@ride).to be_valid
    end

    it 'should require driver_id' do
      @ride.driver_id = nil
      expect(@ride).to_not be_valid
    end

    it 'should require start_address_id' do
      @ride.start_address_id = nil
      expect(@ride).to_not be_valid
    end

    it 'should require dest_address_id' do
      @ride.dest_address_id = nil
      expect(@ride).to_not be_valid
    end

    it 'scope :ran should return rides with non-null ride_score' do
      ran_rides = Ride.ran
      expect(ran_rides).to_not be_empty
      expect(ran_rides.all? { |ride| ride.ride_score.present? }).to be true
    end
  end

  describe 'handle_drive_data' do
    it 'should fetch data from API' do
      # If no rides have 'ran', use Directions API
      Ride.update_all(ride_score: nil)
      expect_any_instance_of(Ride).to receive(:api_directions).once
      expect_any_instance_of(Ride).to_not receive(:drive_data_from_existing)

      new_ride = Ride.new
      new_ride.handle_drive_data({ start_address_id: @addr1.id, dest_address_id: @addr2.id })
    end

    it 'should fetch data from existing ride' do
      # If the addresses are from existing ride, use those
      expect_any_instance_of(Ride).to_not receive(:api_directions)
      expect_any_instance_of(Ride).to receive(:drive_data_from_existing).once

      new_ride = Ride.new
      new_ride.handle_drive_data({
        start_address_id: @ride.start_address_id,
        dest_address_id: @ride.dest_address_id
      })
    end
  end

  describe 'api_directions' do
    it 'error when driver has no home address (should not happen)' do
      @ride.driver.home_address = nil
      expect(@ride.api_directions).to eq({ error: "unable to save ride: missing driver data" })
    end

    it 'error when DirectionsApi returns an error for commute trip' do
      allow(DirectionsApi).to receive(:get_directions).with(@driver.home_address, @ride.start_address)
            .and_return({ error: "some error" })
      expect(@ride.api_directions).to eq({ error: "Error calculating commute: some error" })
    end

    it 'error when DirectionsApi returns an error for ride trip' do
      # valid commute
      allow(DirectionsApi).to receive(:get_directions).with(@driver.home_address, @ride.start_address)
            .and_return({ distance: 10.123, duration: 20.456 })
      # error on ride
      allow(DirectionsApi).to receive(:get_directions).with(@ride.start_address, @ride.dest_address)
            .and_return({ error: "another error" })
      expect(@ride.api_directions).to eq({ error: "Error calculating ride: another error" })
    end

    it 'populates data when DirectionsApi returns valid data' do
      allow(DirectionsApi).to receive(:get_directions).with(@driver.home_address, @ride.start_address)
            .and_return({ distance: 10.123, duration: 20.456 })
      allow(DirectionsApi).to receive(:get_directions).with(@ride.start_address, @ride.dest_address)
            .and_return({ distance: 30.789, duration: 40.123 })

      expect(@ride).to receive(:earnings).and_return(100)
      expect(@ride).to receive(:score).and_return(50)

      result = @ride.api_directions

      expect(@ride.commute_dist).to eq(10.123)
      expect(@ride.commute_duration).to eq(20.456)
      expect(@ride.ride_dist).to eq(30.789)
      expect(@ride.ride_duration).to eq(40.123)
      expect(@ride.ride_earnings).to eq(100)
      expect(@ride.ride_score).to eq(50)
      expect(result).to be_nil
    end

    it 'returns error when save fails' do
      allow(DirectionsApi).to receive(:get_directions).with(@driver.home_address, @ride.start_address)
            .and_return({ distance: 10.123, duration: 20.456 })
      allow(DirectionsApi).to receive(:get_directions).with(@ride.start_address, @ride.dest_address)
            .and_return({ distance: 30.789, duration: 40.123 })

      allow(@ride).to receive(:save!).and_return(false)
      allow(@ride).to receive_message_chain(:errors, :full_messages).and_return(["save error"])

      expect(@ride.api_directions).to eq({ error: "unable to save ride: save error" })
    end

    it 'populates record data' do
      DirectionsApi.stub(:get_directions, { distance: 10, duration: 20 }) do
        @ride.api_directions
        expect(@ride.commute_dist).to eq(10)
        expect(@ride.commute_duration).to eq(20)
      end
    end
  end

  describe 'earnings' do
    it 'calculates earnings for a short ride' do
      @ride.ride_dist = 0.2
      @ride.ride_duration = 0.2
      expect(@ride.earnings).to eq(12.00)
    end

    it 'calculates earnings for a long ride' do
      @ride.ride_dist = 200
      @ride.ride_duration = 2
      expect(@ride.earnings).to eq(305.73)
    end

    it 'handles call with nil ride_dist and ride_duration' do
      @ride.ride_dist = nil
      expect(@ride.earnings).to be_nil

      @ride.ride_dist = 1
      @ride.ride_duration = nil
      expect(@ride.earnings).to be_nil
    end
  end

  describe 'score' do
    it 'return value' do
      @ride.commute_duration = 1.75
      @ride.ride_duration = 2.25
      @ride.ride_earnings = 305.73
      expect(@ride.score).to eq(76.433)
    end

    it 'is nil when a duration is blank' do
      @ride.ride_dist = 200
      @ride.ride_duration = nil
      @ride.ride_earnings = 305.73
      expect(@ride.score).to be_nil
    end

    it 'is 0 when there are no earnings (should not happen)' do
      @ride.ride_dist = 200
      @ride.ride_duration = 2
      @ride.ride_earnings = 0
      expect(@ride.score).to eq(0)
    end
  end

  describe 'drive_data_from_existing' do
    it 'copies DRIVE_DATA columns from passed-in record' do
      # DRIVE_DATA = [:commute_dist, :commute_duration, :ride_dist, :ride_duration, :ride_earnings, :ride_score]
      @ride.commute_dist = rand*10
      @ride.commute_duration = rand
      @ride.ride_dist = rand*10
      @ride.ride_duration = rand
      @ride.ride_earnings = @ride.earnings
      @ride.ride_score = @ride.score
      newride = Ride.new
      newride.drive_data_from_existing(@ride)

      newride.attributes.each do |k, v|
        if !k.to_sym.in?(Ride::DRIVE_DATA)
          # ensure other columns are not copied over (may not be nil if defaults change)
          expect(newride.attribute_changed?(k)).to be_falsey
        else
          expect(v).to eq @ride.attributes[k]
        end
      end
    end
  end
end

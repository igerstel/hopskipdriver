class Ride < ApplicationRecord
  belongs_to :driver
  belongs_to :start_address, class_name: 'Address', foreign_key: 'start_address_id'
  belongs_to :dest_address, class_name: 'Address', foreign_key: 'dest_address_id'

  # We may have rides without calculated duration/distance, but we need a driver and addresses
  validates :driver_id, presence: true
  validates :start_address_id, presence: true
  validates :dest_address_id, presence: true

  EXTRA_DIST = 5     # miles
  EXTRA_TIME = 0.25  # hours (15 minutes)
  FARE_DIST = 1.5    # dollar multiplier for extra distance
  FARE_TIME = 0.7    # dollar multiplier for extra time

  # filters out rides that were not run (no distance/duration/earnings/score)
  scope :ran, -> { where('ride_score is not null') }

  def api_directions
    # Commute trip
    commute_data = DirectionsApi.get_directions(driver.home_address, start_address)
    if commute_data[:error].present?
      return { error: commute_data[:error] }
    end
    self.commute_dist = commute_data[:distance].round(3)
    self.commute_duration = commute_data[:duration].round(3)

    # Ride trip
    ride_data = DirectionsApi.get_directions(start_address, dest_address)
    if ride_data[:error].present?
      return { error: ride_data[:error] }
    end
    self.ride_dist = ride_data[:distance].round(3)
    self.ride_duration = ride_data[:duration].round(3)

    # Ride earnings and score
    self.ride_earnings = earnings
    self.ride_score = score

    unless save!
      return { error: "unable to save ride: #{ride.errors.full_messages.join(', ')}" }
    end
  end

  # float of dollars.cents
  def earnings
    long_dist = [0, ride_dist - EXTRA_DIST].max  # get distance beyond EXTRA miles (min 0)
    long_time = [0, ride_duration - EXTRA_TIME].max  # get time beyond EXTRA hours (min 0)
    return (12 + FARE_DIST*long_dist + FARE_TIME*long_time).round(2)
  end

  def score
    return (ride_earnings.to_f / (commute_duration + ride_duration)).round(3)
  end
end

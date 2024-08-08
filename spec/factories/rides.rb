FactoryBot.define do
  factory :ride do
    association :driver
    association :start_address, factory: :address
    association :dest_address, factory: :address
    commute_dist { rand*10 }
    commute_duration { rand*3 }
    ride_dist { rand*20 }
    ride_duration { rand*4 }

    after(:build) do |ride|
      ride.ride_earnings = ride.earnings
      ride.ride_score = ride.score
    end
  end
end

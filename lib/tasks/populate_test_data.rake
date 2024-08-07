namespace :test_data do
  # rails test_data:specific_data
  # To populate with Directions API (COSTS MONEY): rails test_data:specific_data\['CALL_API'\]
  desc "Populate specific test data"
  task :specific_data, [:arg1] => :environment do |task, args|
    # only run in dev and test!
    break if !(Rails.env.development? || Rails.env.test?)

    # ADDRESSES
    # home
    a1 = Address.where(street: '7870 Van Nuys Blvd',
      city: 'Panorama City',
      state: 'CA',
      zip: '91402'
    ).first_or_create

    # cafe
    a2 = Address.where(street: '14308 Victory Blvd',
      city: 'Van Nuys',
      state: 'CA',
      zip: '91401'
    ).first_or_create

    # boba
    a3 = Address.where(street: '13756 Roscoe Blvd',
      city: 'Panorama City',
      state: 'CA',
      zip: '91402'
    ).first_or_create

    # comedy
    a4 = Address.where(street: '102 E Magnolia Blvd',
      city: 'Burbank',
      state: 'CA',
      zip: '91502'
    ).first_or_create

    # very far
    a5 = Address.where(street: '1622 N 45th St',
      city: 'Seattle',
      state: 'WA',
      zip: '98103'
    ).first_or_create

    # pickup
    a6 = Address.where(street: '12700 Ventura Blvd',
      city: 'Studio City',
      state: 'CA',
      zip: '91604'
    ).first_or_create

    # westside
    a7 = Address.where(street: '200 Santa Monica Pier',
      city: 'Santa Monica',
      state: 'CA',
      zip: '90401'
    ).first_or_create

    # west home
    a8 = Address.where(street: '1323 3rd St',
      city: 'Santa Monica',
      state: 'CA',
      zip: '90401'
    ).first_or_create

    # invalid
    a9 = Address.where(street: '123 FAKE STREET',
      city: 'Burbank',
      state: 'CA',
      zip: '91502'
    ).first_or_create


    # DRIVERS
    # sfv driver
    d1a1 = Driver.where(home_address: a1).first_or_create

    # westside driver
    d2a8 = Driver.where(home_address: a8).first_or_create


    # RIDES
    # Note: ride data collected from Google Directions around 7pm, Aug 5 2024
    # d1 pickup to comedy
    r1d1 = Ride.where(driver: d1a1,
      start_address: a6,
      dest_address: a4
    ).first_or_create

    # d1 pickup to boba
    r2d1 = Ride.where(driver: d1a1,
      start_address: a6,
      dest_address: a3
    ).first_or_create

    # d1 pickup to boba again
    r3d1 = Ride.where(driver: d1a1,
      start_address: a6,
      dest_address: a3
    ).first_or_create

    # d1 pickup to westside
    r4d1 = Ride.where(driver: d1a1,
      start_address: a6,
      dest_address: a7
    ).first_or_create

    # d1 pickup to very far
    r5d1 = Ride.where(driver: d1a1,
      start_address: a6,
      dest_address: a5
    ).first_or_create  # This should not save driving details even when called; returns 'too far' error.

    # d2 westside to comedy
    r6d2 = Ride.where(driver: d2a8,
      start_address: a7,
      dest_address: a4
    ).first_or_create

    # d2 westside to boba
    r7d2 = Ride.where(driver: d2a8,
      start_address: a7,
      dest_address: a3
    ).first_or_create

    # d2 boba to comedy
    r8d2 = Ride.where(driver: d2a8,
      start_address: a3,
      dest_address: a4
    ).first_or_create

    # d1 boba to invalid
    r9d1 = Ride.where(driver: d1a1,
      start_address: a3,
      dest_address: a9
    ).first_or_create

    # populate with Google Directions API if blank and arg1 passed in
    if args[:arg1] == 'CALL_API'
      [r1d1, r2d1, r3d1, r4d1, r5d1, r6d2, r7d2, r8d2, r9d1].each do |r|
        r.api_directions if r.ride_earnings.blank?
      end
    end
  end

  # rails test_data:pagination_data
  desc "Ensure we have >= 50 rides for pagination tests (10/page)"
  task pagination_data: [:environment] do
    if Ride.count == 0
      puts "!!!!!!!!!!"
      puts "RUN 'RAILS_ENV=<env> rails test_data:specific_data' FIRST!"
      puts "!!!!!!!!!!"
    end

    ride_count = Ride.count
    to_make = 50 - ride_count
    return if to_make <= 0

    ((to_make / ride_count)+1).times do |dups|
      old_rides = Ride.order('random()').first(ride_count)
      old_rides.each do |ride|
        r = ride.dup
        r.save
      end
    end
  end
end

class DirectionsApi
  MAPS_API_KEY = ENV['MAPS_API_KEY']
  BASE_URL = 'https://maps.googleapis.com/maps/api/directions/json'
  SEC_TO_HR = 3600

  # Currently this is assumed to be needed in near-real-time.
  # In the future, could move these calls async and callback/webhook
  # to reduce app load, particularly if the service is slow. (DelayedJob/Resque/Sidekiq)

  # addresses come from Address records so they are already validated columnwise
  def self.get_directions(start_addr, dest_addr)
    # safety checks
    if start_addr.blank? || dest_addr.blank? || start_addr == dest_addr
      return { error: "There is a problem with the addresses" }
    end

    start_addr = model_to_address(start_addr) if start_addr.is_a?(Address)
    dest_addr = model_to_address(dest_addr) if dest_addr.is_a?(Address)

    # assuming driving, avoiding tolls
    params = {
      origin: start_addr,
      destination: dest_addr,
      key: MAPS_API_KEY,
      mode: 'driving',
      avoid: 'tolls'
      # FUTURE: avoid tolls and/or highways?
    }

    response = RestClient.get(BASE_URL, { params: params })
    json_resp = JSON.parse(response)

    if json_resp['status'] == 'OK'
      # there may be multiple routes and legs
      time = min_travel_time(json_resp['routes'])
      dist = min_travel_dist(json_resp['routes'])
    else
      return { error: "Error retrieving data: #{json_resp['error_message']}" }
    end

    # handle too far away
    if time > Ride::MAX_TIME || dist > Ride::MAX_DIST
      return { error: "Time or distance is too large for this trip" }
    end

    return { distance: dist, duration: time }
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error("DirectionsApi Rescue!: #{e.response.inspect}")
    return { error: "An error occurred: #{e.response.body}" }
  end

  # stringify the model
  def self.model_to_address(a)
    return "#{a.street},#{a.city},#{a.state},#{a.zip}"
  end


  private

  # compile set values from array of routes->legs
  # returns [{ 'text': 'xyz', 'value': 123 }, { ... }, ...]
  def self.travel_compare(json_routes, key)
    values = []
    json_routes.each do |route|
      legs = route['legs']
      values << legs.collect{|l| l[key]}
    end

    return values.flatten
  end

  # DISTANCE METHODS
  def self.min_travel_dist(json_routes)
    dists = travel_compare(json_routes, 'distance')

    # array of hashes, remove empty hashes
    dists ||= []
    dists&.delete_if(&:empty?)
    if dists.count == 0
      return { error: "No distance found for this trip!" }
    end

    return min_dist(dists)
  end

  # always have dists; caller method checks for emptiness
  def self.min_dist(dists)
    min_dist = Float::INFINITY
    dists.each do |dist|
      d = dist['text'][0..-3].to_f  # remove 'mi'/'ft' and make a number
      d = (d/5280) if dist['text'][-2..-1] == 'ft'  # convert to miles
      min_dist = d if d < min_dist
    end

    return min_dist  # assumption is if ft ~ 0 miles it's all the same by car
  end

  # TRAVEL DURATION METHODS
  def self.min_travel_time(json_routes)
    durations = travel_compare(json_routes, 'duration')

    # array of hashes, remove empty hashes
    durations ||= []
    durations&.delete_if(&:empty?)
    if durations.count == 0
      return { error: "No travel time found for this trip!" }
    end

    return min_time(durations)
  end

  # 'value' is in seconds, find minimum and return fraction of hours
  # always have times; caller method checks for emptiness
  def self.min_time(times)
    min_time = times.collect{|c| c['value']}.min.to_f
    return min_time/SEC_TO_HR
  end
end

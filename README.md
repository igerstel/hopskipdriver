# README

NOTE:
* CALCULATIONS BASED ON ESTIMATES; WOULD HAVE ANOTHER MODEL FOR RECEIPT/HISTORY ACTUALLY USED, TIME ACTUALLY TAKEN, PICKUP TIME, DROPOFF TIME, ETC ETC

* USING PRECISION(3) AND .ROUND(2) HERE


!!!!!! ADD API DOCS


CREATE ADDRESS
POST: localhost:3000/addresses?address[street]=123 fake st&address[city]=los angeles&address[state]=ca&address[zip]=91402

UPDATE ADDRESS

CREATE DRIVER

UPDATE DRIVER


CREATE RIDE
POST:

UPDATE RIDE
PATCH: localhost:3000/rides/57?ride[dest_address_id]=13



Installation and Setup:

# get code and set up environment
git clone
bundle install
rails db:migrate
RAILS_ENV=test rails db:migrate  # may not be necessary?
add .env
rails generate rspec:install

# to set up dev env with current Directions API calls
rails test_data:specific_data\['CALL_API'\]
# OR: to set up dev env with earlier saved data from Directions API
rails test_data:specific_data

# to duplicate records to view pagination
rails test_data:pagination_data

# start server
rails s

# testing:
rspec spec




Shortcomings:

Currently when there is an error, the message is returned but there is no effort to fix or retry things. Google's optimization guide for Maps suggests an exponential backoff of retries to get a response.


Directions / Caching:

As a basic first pass, we are assuming that driving times and distances are constant between given addresses, and check for their existence before making a Directions API call to reduce cost. The two big drawbacks to this are:
1) Traffic, construction, and events can make temporary but large changes to this data, and
2) Addresses must be exact, so if we have House A and we get a ride from House B just next door, it is not smart enough to realize it can use House A.


Future ideas and drawbacks:
Location Boxing:
* In some cases this could be fixed by using the lat/lng coordinates and checking for existing records within, say, 0.0001 (~40 feet or 0.0068 miles).
* However, existing barriers (up a cliff, other side of aqueduct, etc) could greatly affect routes even if the distance between places is technically small.

Time Bucketing:
* We could check for existing rides between two addresses and factor in the created_at time. It could be as simple as having two buckets, 'peak' and 'normal', so if we have an existing ride that was during rush hour, and the new ride also is, we can use those values instead of calling the API.
* This would not catch events like construction but may be a worthwhile tradeoff.
* As more data is collected, we could set up averages from aggregated blocks of time and compare the difference to the actual data. When the error % is low enough we can 'trust' that data, and if we start to see things skew outside the range (for instance if a road opens or closes) then we can go back to making API calls until we get more stable results.







Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

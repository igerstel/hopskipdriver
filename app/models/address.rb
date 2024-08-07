class Address < ApplicationRecord
  # NOTE: address.rides/drivers is not valid (could be home, start, destination, etc)
  # to find relations, go through other model ie Driver.where(home_address_id: 1)
  # FUTURE: add scopes for these relations
  has_many :drivers
  has_many :rides

  validates :street, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :zip, presence: true

  # FUTURE: hash ids for safety/privacy
end

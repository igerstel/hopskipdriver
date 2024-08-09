class Driver < ApplicationRecord
  has_many :rides
  belongs_to :home_address, class_name: 'Address', foreign_key: 'home_address_id'

  # Address must exist before Driver
  validates :home_address_id, presence: true

  # FUTURE: getting 2 API results when missing home_address; reduce to 1.
  # FUTURE: hash ids for safety/privacy, remove :id from output
  # FUTURE: may want driver home_address history, if driver moves and
  #     we need to preserve historic 'commute' data
end

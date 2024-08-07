class Driver < ApplicationRecord
  has_many :rides
  belongs_to :home_address, class_name: 'Address', foreign_key: 'home_address_id'

  # Address must exist before Driver
  validates :home_address_id, presence: true
end

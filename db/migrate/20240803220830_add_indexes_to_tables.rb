class AddIndexesToTables < ActiveRecord::Migration[7.1]
  def change
    add_index :drivers, :home_address_id
    add_index :rides, :driver_id
    add_index :rides, :start_address_id
    add_index :rides, :dest_address_id
    add_index :rides, :ride_score
  end
end

class CreateRides < ActiveRecord::Migration[7.1]
  def change
    create_table :rides do |t|
      t.bigint :driver_id
      t.bigint :start_address_id
      t.bigint :dest_address_id
      t.float :commute_dist, precision: 3, scale: 2
      t.float :commute_duration, precision: 3, scale: 2
      t.float :ride_dist, precision: 3, scale: 2
      t.float :ride_duration, precision: 3, scale: 2
      t.float :ride_earnings, precision: 3, scale: 2
      t.float :ride_score, precision: 3, scale: 2

      t.timestamps
    end
  end
end

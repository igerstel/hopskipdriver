class CreateDrivers < ActiveRecord::Migration[7.1]
  def change
    create_table :drivers do |t|
      t.bigint :home_address_id

      t.timestamps
    end
  end
end

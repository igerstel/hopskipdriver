# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_08_03_220830) do
  create_table "addresses", force: :cascade do |t|
    t.string "street"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "drivers", force: :cascade do |t|
    t.bigint "home_address_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["home_address_id"], name: "index_drivers_on_home_address_id"
  end

  create_table "rides", force: :cascade do |t|
    t.bigint "driver_id"
    t.bigint "start_address_id"
    t.bigint "dest_address_id"
    t.float "commute_dist"
    t.float "commute_duration"
    t.float "ride_dist"
    t.float "ride_duration"
    t.float "ride_earnings"
    t.float "ride_score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dest_address_id"], name: "index_rides_on_dest_address_id"
    t.index ["driver_id"], name: "index_rides_on_driver_id"
    t.index ["ride_score"], name: "index_rides_on_ride_score"
    t.index ["start_address_id"], name: "index_rides_on_start_address_id"
  end

end

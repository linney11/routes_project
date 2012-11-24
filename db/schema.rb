# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121121013744) do

  create_table "general_routes", :force => true do |t|
    t.string "name",        :null => false
    t.string "description"
  end

  create_table "gps_samples", :force => true do |t|
    t.float   "latitude",  :limit => 53, :null => false
    t.float   "longitude", :limit => 53, :null => false
    t.integer "timestamp", :limit => 8,  :null => false
    t.integer "route_id"
  end

  create_table "nfc_samples", :force => true do |t|
    t.string  "message"
    t.integer "timestamp",     :limit => 8, :null => false
    t.integer "gps_sample_id"
  end

  create_table "routes", :force => true do |t|
    t.string  "name",             :null => false
    t.string  "description"
    t.integer "general_route_id"
  end

  create_table "surveys", :force => true do |t|
    t.string  "answer"
    t.integer "timestamp",     :limit => 8, :null => false
    t.integer "nfc_sample_id"
  end

end

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

ActiveRecord::Schema[8.1].define(version: 0) do
  create_table "affordability_assessments", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.decimal "debt_to_income_ratio", precision: 5, scale: 2, null: false
    t.string "decision", limit: 255, null: false
    t.text "explanation"
    t.decimal "loan_to_value", precision: 5, scale: 2, null: false
    t.decimal "max_borrowing_estimate", precision: 12, scale: 2, null: false
    t.integer "mortgage_application_id", null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "mortgage_applications", force: :cascade do |t|
    t.decimal "annual_income", precision: 12, scale: 2, null: false
    t.datetime "created_at", precision: nil, null: false
    t.decimal "deposit_amount", precision: 12, scale: 2, null: false
    t.decimal "monthly_expenses", precision: 12, scale: 2, null: false
    t.decimal "property_value", precision: 12, scale: 2, null: false
    t.integer "term", null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  add_foreign_key "affordability_assessments", "mortgage_applications"
end

class CreateAffordabilityAssessments < ActiveRecord::Migration[8.1]
  def change
    create_table :affordability_assessments do |t|
      t.references :mortgage_application, null: false, foreign_key: true
      t.decimal :loan_to_value, precision: 5, scale: 2, null: false
      t.decimal :debt_to_income_ratio, precision: 5, scale: 2, null: false
      t.string :decision, null: false
      t.decimal :max_borrowing_estimate, precision: 12, scale: 2, null: false
      t.text :explanation
      t.timestamps
    end
  end
end
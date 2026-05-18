class RenameTermToTermYearsOnMortgageApplications < ActiveRecord::Migration[8.1]
  def change
    rename_column :mortgage_applications, :term, :term_years
  end
end

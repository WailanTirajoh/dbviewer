class AddNotNullConstraintToCompaniesName < ActiveRecord::Migration[8.0]
  def change
    change_column_null :companies, :name, false
  end
end

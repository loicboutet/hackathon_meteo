class AddAttributesToCity < ActiveRecord::Migration
  def change
    add_column :cities, :weather, :string
    add_column :cities, :tide, :float
    add_column :cities, :api_updated, :datetime
  end
end

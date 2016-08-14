class AddDeleteFileToTask < ActiveRecord::Migration
  def self.up
    add_column :tasks, :delete_file, :boolean
  end

  def self.down
    drop_column :tasks, :delete_file
  end
end

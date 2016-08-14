class AddXportOptionsToTask < ActiveRecord::Migration
  def self.up
    add_column :tasks, :xport_options, :string
  end

  def self.down
    drop_column :tasks, :xport_options
  end
end

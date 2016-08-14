class CreateTasks < ActiveRecord::Migration
  def self.up
    create_table :tasks do |t|
      t.string :status

      t.string :file_name
      t.string :file_path
      t.string :destination
      t.string :tags
      t.text :cart

      t.integer :priority

      t.timestamps
    end
  end

  def self.down
    drop_table :tasks
  end
end

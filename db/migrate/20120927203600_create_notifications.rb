class CreateNotifications < ActiveRecord::Migration
  def self.up
    create_table :notifications do |t|
      t.belongs_to :task
      t.belongs_to :notifier
      t.time :sent_at
      t.timestamps
    end
  end

  def self.down
    drop_table :notifications
  end
end

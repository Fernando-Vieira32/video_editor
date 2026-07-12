class CreateVideoTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :video_tasks do |t|
      t.string :operation, null: false
      t.integer :status, null: false, default: 0
      t.jsonb :params, null: false, default: {}
      t.text :error_message

      t.timestamps
    end

    add_index :video_tasks, :status
    add_index :video_tasks, :created_at
  end
end

class CreateJobExecutions < ActiveRecord::Migration[6.0]
  def change
    create_table :job_executions do |t|
      t.string :provider_job_id, null: false
      t.integer :duration, null: false

      t.timestamps
    end
  end
end

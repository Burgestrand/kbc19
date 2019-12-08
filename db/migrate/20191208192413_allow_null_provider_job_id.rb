class AllowNullProviderJobId < ActiveRecord::Migration[6.0]
  def change
    change_column_null(:job_executions, :provider_job_id, allow_null = true)
  end
end

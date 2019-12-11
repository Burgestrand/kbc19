Hi Kim!

Many thanks for this awesome submission. I went through all (I hope) files and have a few follow-up questions - no coding needed, just conceptual stuff!

Hope that's fine! :)

# Worker:

https://github.com/Burgestrand/kbc19/blob/master/lib/tasks/active_job.rake all good here! Clean and concise!

# Jobs:

https://github.com/Burgestrand/kbc19/blob/master/app/jobs/application_job.rb#L5: we may want to file this as a bug in rails/rails; if I remember correctly connection pool errors during deserialize would lead to discard!

# Adapter:

https://github.com/Burgestrand/kbc19/blob/master/app/jobs/google_pub_sub_adapter.rb

- Maybe should go to lib? Unsure.
- Naming: Queue makes sense to way we use it!
- I would suggest to put execution into the worker, so the adapter only deals with enqueueing
- https://github.com/Burgestrand/kbc19/blob/master/app/jobs/google_pub_sub_adapter.rb#L105 what would you do if execution errored out? Currently this would take the job processor down. Think of at-least-once vs at-most-once, or job duplication vs job loss.
- https://github.com/Burgestrand/kbc19/blob/master/app/jobs/google_pub_sub_adapter.rb#L30 benefit of tap vs second line `raise unless @topic`
- https://github.com/Burgestrand/kbc19/blob/master/app/jobs/google_pub_sub_adapter.rb#L28 what if two Rails instances have race condition in creating topics - how to avoid/handle?

# Docs

Very neatly documented!

# Tests

Love that even the home page is tested! =D

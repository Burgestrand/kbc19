# Santa

This is a sample Rails 6 app to house an active job adapter implementation.

It has been stripped down to remove distractions. Uses sqlite3 in development
for ease of getting started, in practice we'd probably want to mimic production
as close as possible.

## Notes

1. We schedule both `enqueue` and `enqueue_at` jobs on the same queue. We could schedule
   them on different queues to avoid scheduled jobs taking unnecessary power from acute
   work… but frankly there's no reason to at this time. If it becomes a problem, sure.
1. There's no support for different job priorities.

## Development

1. Make sure you have Ruby installed (see `.tool-versions`).
1. Make sure you have external dependencies installed (see `Brewfile`).
2. Make sure you have  `./config/master.key`. Ask your colleagues!
3. Run setup, `bin/setup`.

#### Configuration

- `GOOGLE_CLOUD_CREDENTIALS` — service account credentials for our Google Cloud account. Retrieved from `ENV` in production, but from secret credentials in development.

#### Google Pub/Sub Considerations

1. Work queues (topics/subscriptions) need to be created ahead of time. To do so run `rails active_job:setup`, see `lib/tasks/active_job.rake`. `bin/setup` does this for you.

### Deviations from standard Rails

* Using `.tools-version` instead of `.ruby-version`, see <https://asdf-vm.com/>.
* Using rspec instead of minitest.

### Testing

1. Run the suite through `bin/rails spec`.

## Troubleshooting

> RuntimeError: grpc cannot be used before and after forking

I hope you're in the console, trying to perform a job. Try this console command:

```
DISABLE_SPRING=true bin/rails console
```
# Santa

This is a sample Rails 6 app to house an action cable adapter implementation.

It has been stripped down to remove distractions. Uses sqlite3 in development
for ease of getting started, in practice we'd probably want to mimic production
as close as possible.

## Development

1. Make sure you have Ruby installed (see `.tool-versions`).
1. Make sure you have  `./config/master.key`. Ask your colleagues!
1. Run setup, `bin/setup`.

#### Configuration

- `GOOGLE_CLOUD_CREDENTIALS` — service account credentials for our Google Cloud account. Retrieved from `ENV` in production, but from secret credentials in development.

#### Google Pub/Sub Considerations

1. Work queues (topics/subscriptions) need to be created ahead of time. To do so run `rails active_job:setup`, see `lib/tasks/active_job.rake`. `bin/setup` does this for you.

### Deviations from standard Rails

* Using `.tools-version` instead of `.ruby-version`, see <https://asdf-vm.com/>.
* Using rspec instead of minitest.

### Testing

1. Run the suite through `bin/rails spec`.
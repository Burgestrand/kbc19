# Santa

This is a sample Rails 6 app to house an action cable adapter implementation.

It has been stripped down to remove distractions. Uses sqlite3 in development
for ease of getting started, in practice we'd probably want to mimic production
as close as possible.

## Development

1. Make sure you have Ruby installed (see `.tool-versions`).
1. Install dependencies, `bundle install`
1. Create your databases, `rails db:setup`.
1. Make sure you have access to application secret credentials, `./config/master.key`. Ask your colleagues!
1. Launch, `rails s`!

### Deviations from standard Rails

* Using `.tools-version` instead of `.ruby-version`, see <https://asdf-vm.com/>.
* Using rspec instead of minitest.

### Testing

* We don't use fixtures, or factories, because there's no need yet.

1. Run the suite through `bundle exec rspec`.

### Deployment

Notes about deployment.

1. Additional setup.
1. Deploying the application.

#### Environment variables

- `GOOGLE_CLOUD_CREDENTIALS` — service account credentials for our Google Cloud account.
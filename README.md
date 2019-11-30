# Santa

This is a sample Rails 6 app to house an action cable adapter implementation. It's
a book keeping application for Santa Claus, to keep track of children.

It has been stripped down to remove distractions.

1. No asset pipeline, sprockets, webpack, etc.
1. No action mailer/mailbox/text.
1. sqlite3 database in development, to avoid requiring more dependencies.
1. No internationalization or localization.

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

Notes about test environment.

1. Additional setup.
1. Running the test suite.

### Deployment

Notes about deployment.

1. Additional setup.
1. Deploying the application.
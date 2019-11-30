# Arbetsförmedlingen

This is a sample Rails 6 app to house an action cable adapter implementation.

It's been stripped down to remove distractions.

1. No asset pipeline, sprockets, webpack, etc.
1. No action mailer/mailbox/text.
1. In-memory sqlite3 database, i.e. no persistence.
1. No internationalization or localization.

## Development

General notes.

* Recommendations.

### Deviations from standard Rails

* Using `.tools-version` instead of `.ruby-version`, see <https://asdf-vm.com/>.
* Using rspec instead of minitest.

### Setup

1. Language and tool dependencies.
2. Environment and secrets.
3. Running the application.

### Testing

Notes about test environment.

1. Additional setup.
1. Running the test suite.

### Deployment

Notes about deployment.

1. Additional setup.
1. Deploying the application.
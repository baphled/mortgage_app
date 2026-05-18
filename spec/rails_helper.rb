# This file is copied to spec/ when you run 'bin/rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this glob with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec` by setting
# `--pattern` glob to not match files ending in `_spec.rb` while also not
# requiring the files in spec/support to end with `_spec.rb`. To configure this
# see the RSpec configuration docs.

# The following line is provided for convenience purposes. It has the downside
# of increasing the booting time of your test suite. Because you only need to
# boot the test suite once during your development workflow, the performance
# penalty is bearable. For convenience, you may want to remove this line in
# your own test suite.

# Load support files
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Begin RSpec configuration

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [ Rails.root.join('spec/fixtures').to_s ]

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails can automatically mix in different types of examples using this
  # configure. This option must be enabled before any other configuration
  # settings, including requiring any shared example groups.
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end
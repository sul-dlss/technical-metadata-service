# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
# require "active_storage/engine"
require 'action_controller/railtie'
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require 'action_view/railtie'
# require "action_cable/engine"
require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

class JSONAPIError < Committee::ValidationError
  def error_body
    {
      errors: [
        { status: id, detail: message }
      ]
    }
  end

  def render
    [
      status,
      { 'Content-Type' => 'application/vnd.api+json' },
      [JSON.generate(error_body)]
    ]
  end
end

# Parent class for characterization errors, helps us trap for any characterization errors
class CharacterizationError < StandardError
end

module TechnicalMetadataService
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.autoload_once_paths += Dir[Rails.root.join('app', 'serializers')] # rubocop:disable Rails/RootPathnameMethods

    # accept_request_filter omits OKComputer and Sidekiq
    accept_proc = proc { |request| request.path.start_with?('/v1') }
    config.middleware.use Committee::Middleware::RequestValidation,
                          schema_path: 'openapi.yml',
                          strict: true,
                          error_class: JSONAPIError,
                          accept_request_filter: accept_proc,
                          parse_response_by_content_type: false,
                          query_hash_key: 'action_dispatch.request.query_parameters',
                          parameter_overwrite_by_rails_rule: false,
                          strict_reference_validation: true
    config.middleware.use Committee::Middleware::ResponseValidation,
                          schema_path: 'openapi.yml',
                          parse_response_by_content_type: false,
                          query_hash_key: 'rack.request.query_hash',
                          parameter_overwrite_by_rails_rule: false,
                          strict_reference_validation: true
  end
end

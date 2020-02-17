# frozen_string_literal: true

Sidekiq.configure_server do |_config|
  ActiveRecord::Base.logger = Sidekiq::Logging.logger
  Rails.logger = Sidekiq::Logging.logger
end

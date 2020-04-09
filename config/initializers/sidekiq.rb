# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = { url: Settings.redis_url }
  ActiveRecord::Base.logger = Sidekiq::Logging.logger
  Rails.logger = Sidekiq::Logging.logger
end

Sidekiq.configure_client do |config|
  config.redis = { url: Settings.redis_url }
end

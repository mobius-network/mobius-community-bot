source 'https://rubygems.org'

ruby '~> 2.7'

gem 'dotenv-rails', require: 'dotenv/rails-now', groups: %i[development test]
gem 'rails', '~> 5.2.8'

gem 'bigdecimal'
gem 'dry-initializer', '~> 3.1'
gem 'redis-rails', '~> 5.0'
gem 'light-service', '~> 0.18'
gem 'openssl'
gem 'pg', '~> 1.3'
gem 'puma', '~> 5.6'
gem 'rack-cors', '~> 1.0', require: 'rack/cors'
gem 'stellar-sdk', '~> 0.32'
gem 'sucker_punch', '~> 3.0'
gem 'telegram-bot', '~> 0.15'
gem 'telegram-bot-types', '~> 0.7'

group :development do
  gem "bundler-audit", require: false
  gem 'listen'
  gem 'spring'
  gem 'spring-watcher-listen'
end

group :development, :test do
  gem 'awesome_print'
  gem 'hirb'
  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-docmore'
  gem 'pry-rails'
  gem 'rspec-its'
  gem 'rspec-rails'
  gem 'spring-commands-rspec'
end

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}.git" }

ruby '~> 2.5'

gem 'dotenv-rails', require: 'dotenv/rails-now', groups: %i[development test]
gem 'rails', '~> 5.2.1'

gem 'bigdecimal'
gem 'dry-initializer', '~> 2.4'
gem 'redis-rails', '~> 5.0'
gem 'light-service', '~> 0.10.3'
gem 'openssl'
gem 'pg', '~> 1.0'
gem 'puma', '~> 3.7'
gem 'rack-cors', '~> 1.0', require: 'rack/cors'
gem 'stellar-sdk', '~> 0.5'
gem 'sucker_punch', '~> 2.0'
gem 'telegram-bot', '~> 0.14'
gem 'telegram-bot-types', '~> 0.5'

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
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

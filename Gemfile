# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :development do
  gem "activemodel", ">= 6.0"
  gem "irb"
  gem "rake", "~> 13.0"
  gem "rspec", "~> 3.0"

  # Rubocop changes pretty quickly: new cops get added and old cops change
  # names or go into new namespaces. This is a library and we don't have
  # `Gemfile.lock` checked in, so to prevent good builds from suddenly going
  # bad, pin to a specific version number here.
  gem "rubocop", "1.75.2" if RUBY_VERSION >= "2.7"
  gem "rubocop-rspec", "~> 3.0" if RUBY_VERSION >= "2.7"

  platforms :mri do
    gem "byebug"
    gem "pry"
    gem "pry-byebug"
  end
end

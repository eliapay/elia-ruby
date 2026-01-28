# frozen_string_literal: true

require "zeitwerk"
require "active_support"
require "active_support/core_ext/module/delegation"
require "active_support/core_ext/object/blank"

# Define the Elia module at the top level
module Elia
  class Error < StandardError; end
end

require_relative "elia_ruby/version"

# Set up Zeitwerk loader for Elia::Mcc namespace
loader = Zeitwerk::Loader.new
loader.tag = "elia_mcc"
loader.push_dir(File.expand_path("elia", __dir__), namespace: Elia)

# Ignore files that don't follow Zeitwerk conventions
loader.ignore(File.expand_path("elia/mcc/version.rb", __dir__))
loader.ignore(File.expand_path("elia/mcc/errors.rb", __dir__))
loader.ignore(File.expand_path("elia/mcc/railtie.rb", __dir__))
loader.ignore(File.expand_path("elia/mcc/active_model_validator.rb", __dir__))
loader.ignore(File.expand_path("elia/mcc/data", __dir__))

loader.setup

# Load files that don't follow Zeitwerk conventions manually
require_relative "elia/mcc/version"
require_relative "elia/mcc/errors"
require_relative "elia/mcc"

# Load the Railtie if Rails is present
require_relative "elia/mcc/railtie" if defined?(Rails::Railtie)

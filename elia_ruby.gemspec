# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))

require "elia_ruby/version"

Gem::Specification.new do |s|
  s.name = "elia_ruby"
  s.version = Elia::VERSION
  s.required_ruby_version = ">= 2.7.0"
  s.summary = "MCC (Merchant Category Code) library for payment processing"
  s.description = "A comprehensive library for working with Merchant Category Codes (MCC), " \
                  "including validation, categorization, and risk assessment."
  s.author = "Elia Pay"
  s.email = "support@eliapay.com"
  s.homepage = "https://github.com/eliapay/elia-ruby"
  s.license = "MIT"

  s.metadata = {
    "bug_tracker_uri" => "https://github.com/eliapay/elia-ruby/issues",
    "changelog_uri" => "https://github.com/eliapay/elia-ruby/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://github.com/eliapay/elia-ruby#readme",
    "github_repo" => "ssh://github.com/eliapay/elia-ruby",
    "homepage_uri" => "https://github.com/eliapay/elia-ruby",
    "source_code_uri" => "https://github.com/eliapay/elia-ruby",
    "rubygems_mfa_required" => "true",
  }

  included = Regexp.union(
    %r{\Alib/},
    /\ALICENSE\.txt\z/,
    /\AREADME\.md\z/
  )
  s.files = `git ls-files`.split("\n").grep(included)
  s.require_paths = ["lib"]

  s.add_dependency "activesupport", ">= 6.0"
  s.add_dependency "zeitwerk", "~> 2.6"
end

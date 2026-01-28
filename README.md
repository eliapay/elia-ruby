# Elia Ruby

A comprehensive Ruby gem for working with Merchant Category Codes (MCC) in payment processing. Provides validation, categorization, risk assessment, and multi-source data aggregation.

## Features

- **Multi-source MCC data** - Aggregates descriptions from ISO 18245, USDA, Stripe, Visa, Mastercard, American Express, Alipay, and IRS
- **Risk categories** - Pre-defined categories for payment control (gambling, airlines, adult, crypto, etc.)
- **ISO 18245 ranges** - Standard category ranges from the official specification
- **Fuzzy search** - Search across all descriptions to find relevant MCCs
- **Rails integration** - ActiveModel validators and serializers
- **IRS reportable flags** - Know which MCCs require 1099-K reporting

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'elia_ruby'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install elia_ruby
```

## Usage

### Basic Lookup

```ruby
require 'elia_ruby'

# Find an MCC
code = Elia::Mcc.find("5411")
code.mcc                    # => "5411"
code.iso_description        # => "Grocery Stores, Supermarkets"
code.stripe_code            # => "grocery_stores_supermarkets"
code.irs_reportable?        # => false

# Strict lookup (raises if not found)
Elia::Mcc.find!("5411")     # => Elia::Mcc::Code
Elia::Mcc.find!("99999")    # => raises Elia::Mcc::NotFound

# Shorthand
Elia::Mcc["5411"]           # => same as find
```

### Collections and Queries

```ruby
# Get all MCCs
Elia::Mcc.all                          # => Array of all codes

# Filter by attributes
Elia::Mcc.where(irs_reportable: true)  # => IRS reportable codes

# Range queries
Elia::Mcc.in_range("5000", "5999")     # => Retail MCCs

# Search descriptions
Elia::Mcc.search("restaurant")         # => fuzzy search results
```

### Risk Categories

```ruby
# Available categories
Elia::Mcc.categories  # => [:airlines, :gambling, :adult, :crypto, ...]

# Get codes in a category
Elia::Mcc.in_category(:gambling)       # => gambling-related MCCs
Elia::Mcc.in_category(:airlines)       # => airline MCCs only

# Check a code's categories
code = Elia::Mcc.find("7995")
code.categories                        # => [:gambling]
code.in_category?(:gambling)           # => true
```

### ISO 18245 Ranges

```ruby
# Get all ranges
Elia::Mcc.ranges  # => Array of Elia::Mcc::Range objects

# Check a code's range
code = Elia::Mcc.find("5411")
code.range.name   # => "Retail Outlets"
```

### Validation

```ruby
# Check if valid
Elia::Mcc.valid?("5411")   # => true
Elia::Mcc.valid?("99999")  # => false
```

### Rails Integration

#### ActiveModel Validator

```ruby
class Transaction < ApplicationRecord
  validates :mcc_code, mcc: true

  # Or with category restrictions
  validates :mcc_code, mcc: {
    deny_categories: [:gambling, :adult],
    message: "category is blocked"
  }
end
```

#### Configuration

```ruby
# config/initializers/elia_mcc.rb
Elia::Mcc.configure do |config|
  config.default_description_source = :stripe  # or :iso, :visa, etc.
  config.include_reserved_ranges = false
end
```

### Code Attributes

```ruby
code = Elia::Mcc.find("5411")

# Core
code.mcc                     # => "5411"

# Multi-source descriptions
code.iso_description
code.usda_description
code.stripe_description
code.stripe_code             # => programmatic identifier
code.visa_description
code.visa_clearing_name
code.mastercard_description
code.amex_description
code.alipay_description

# IRS
code.irs_description
code.irs_reportable?

# Categorization
code.range                   # => Elia::Mcc::Range
code.categories              # => Array of symbols

# Serialization
code.to_h                    # => Hash with all attributes
code.as_json                 # => JSON-ready hash
```

## Data Sources

This gem aggregates MCC data from multiple authoritative sources:

- **ISO 18245:2023** - The official international standard for MCC definitions
- **USDA** - Comprehensive list including private-use ranges
- **Stripe** - Descriptions with programmatic codes
- **Visa** - Descriptions with clearing names
- **Mastercard** - Descriptions with abbreviated names
- **American Express** - Descriptions
- **Alipay** - Descriptions
- **IRS** - Reportable flags for 1099-K compliance

## Inspiration and Credits

This gem was inspired by and incorporates ideas from several excellent projects:

- [python-iso18245](https://github.com/alubbock/python-iso18245) - Comprehensive Python MCC library with multi-source data aggregation
- [mcc-ruby](https://github.com/singlebrook/mcc-ruby) - Ruby gem with IRS reportable data
- [mcc](https://github.com/maximbilan/mcc) - MCC data collection by Maxim Bilan

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt.

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/eliapay/elia-ruby.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

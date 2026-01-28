# frozen_string_literal: true

module Elia
  module Mcc
    # Rails integration for the Elia::Mcc module
    #
    # Provides automatic setup when used within a Rails application,
    # including configuration and ActiveModel integration.
    class Railtie < Rails::Railtie
      initializer "elia_mcc.configure" do |app|
        # Allow custom data path from Rails config directory
        Elia::Mcc.configure do |config|
          if app.root
            custom_data_path = app.root.join("config", "mcc_data")
            config.data_path = custom_data_path.to_s if custom_data_path.exist?
          end
        end
      end

      # Load ActiveModel validator when ActiveModel is loaded
      initializer "elia_mcc.active_model" do
        ActiveSupport.on_load(:active_model) do
          require "elia/mcc/active_model_validator"
        end
      end

      # Eager load MCC data after initialization if caching is enabled
      config.after_initialize do
        if Elia::Mcc.configuration.cache_enabled
          # Touch the collection to trigger lazy loading
          Elia::Mcc.count
        end
      end
    end
  end
end

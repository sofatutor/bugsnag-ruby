require "httparty"
require "multi_json"

module Bugsnag
  module Capistrano
    def self.load_into(configuration)
      configuration.load do
        after "deploy",            "bugsnag:deploy"
        after "deploy:migrations", "bugsnag:deploy"

        namespace :bugsnag do
          desc "Notify Bugsnag that new production code has been deployed"
          task :deploy, :except => { :no_release => true }, :on_error => :continue do
            # Build the rake command
            rake = fetch(:rake, "rake")
            rails_env = fetch(:rails_env, "production")
            rake_command = "cd '#{current_path}' && #{rake} bugsnag:deploy RAILS_ENV=#{rails_env}"

            # Extract the app version from env vars or the current revision
            app_version = ENV["BUGSNAG_APP_VERSION"] || current_revision
            rake_command << " BUGSNAG_APP_VERSION=#{app_version}" if app_version

            # Pass through any other env variables
            ["BUGSNAG_API_KEY", "BUGSNAG_RELEASE_STAGE"].each do |env|
              rake_command << " #{env}=#{ENV[env]}" if ENV[env]
            end

            # Run the rake command (only on one server)
            run(rake_command, :once => true)
            
            logger.info "Bugsnag deploy notification complete."
          end
        end
      end
    end
  end
end

Bugsnag::Capistrano.load_into(Capistrano::Configuration.instance) if Capistrano::Configuration.instance


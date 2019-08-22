require_relative './lib/dependency_updater.rb'
require_relative './lib/dependency_updater_config.rb'
require_relative './lib/constants.rb'

config             = DependencyUpdaterConfig.new("config.yml")
dependency_updater = DependencyUpdater.new(
  config.dependency_updates,
  Constants::REPO_DIRECTORY,
  config.package_manager
)

dependency_updater.update_dependencies

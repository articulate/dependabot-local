require "yaml"

DependencyUpdate = Struct.new(:name, :ignore_versions, :commit_message)

class DependencyUpdaterConfig
  attr_reader :package_manager, :dependency_updates

  def initialize(file_path)
    config = YAML.load(File.read(file_path))

    @package_manager = config["package_manager"]

    @dependency_updates = config["dependency_updates"].map do |dependency_update|
      DependencyUpdate.new(dependency_update["name"], dependency_update["ignore_versions"], dependency_update["commit_message"])
    end
  end
end

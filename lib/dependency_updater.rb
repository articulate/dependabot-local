require "dependabot/file_fetchers"
require "dependabot/file_parsers"
require "dependabot/update_checkers"
require "dependabot/file_updaters"
require "dependabot/omnibus"

require "pathname"
require 'git'

require_relative './monkey_patch_file_fetchers.rb'

class NoChangeError < StandardError
end

Source = Struct.new(:provider, :directory)

class DependencyUpdater
  def initialize(dependency_updates, directory, package_manager)
    @dependency_updates = dependency_updates
    @directory          = directory
    @git                = Git.open(directory)
    @package_manager    = package_manager
  end

  def update_dependencies
    @dependency_updates.each do |dependency|
      updatedFiles = updateDependency(dependency.name, dependency.ignore_versions)

      if updatedFiles
        @git.add
        @git.commit(dependency.commit_message)
      end
    end
  end

  private

  def updateDependency(dependency_name, ignore_versions)
    puts "Updating #{dependency_name}.  Ignoring versions #{ignore_versions}"

    credentials = []
    source = Source.new('file_system', @directory)

    #############################
    # Fetch the dependency files #
    #############################
    fetcher = Dependabot::FileFetchers.for_package_manager(@package_manager).
              new(source: source, credentials: credentials)

    files = fetcher.files

    #############################
    # Parse the dependency files #
    #############################
    parser = Dependabot::FileParsers.for_package_manager(@package_manager).new(
      dependency_files: files,
      source: source,
      credentials: credentials,
    )

    dependencies = parser.parse
    dep = dependencies.find { |d| d.name == dependency_name }

    #########################################
    # Get update details for the dependency #
    #########################################
    checker = Dependabot::UpdateCheckers.for_package_manager(@package_manager).new(
      dependency: dep,
      dependency_files: files,
      credentials: credentials,
      ignored_versions: [ignore_versions]
    )

    updated_deps = checker.updated_dependencies(requirements_to_unlock: :own)

    #####################################
    # Generate updated dependency files #
    #####################################
    updater = Dependabot::FileUpdaters.for_package_manager(@package_manager).new(
      dependencies: updated_deps,
      dependency_files: files,
      credentials: credentials,
    )

    begin
      updated_files = updater.updated_dependency_files

      raise NoChangeError if updated_files.empty?
    rescue NoChangeError, Dependabot::NpmAndYarn::FileUpdater::NoChangeError
      puts "    ** Skipping #{dependency_name} since no updates were found."
      return false
    end

    updated_files.each do |file|
      path = @directory + '/' + file.name
      puts "    - Updating #{path}"

      File.open(path, 'w') do |f|
        f.write(file.content)
      end
    end

    return true
  end
end

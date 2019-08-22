require "dependabot/file_fetchers"
require "dependabot/file_parsers"
require "dependabot/update_checkers"
require "dependabot/file_updaters"
require "dependabot/omnibus"

require "pathname"
require "yaml"
require 'rubygems'
require 'git'

REPO_DIRECTORY  = "/service/repo" # Directory where the repository being updated is volumed in

####### Monkey patching FileFetchers to read source files from disk
FileStruct = Struct.new(:name, :path, :type, :size)

module Dependabot
  module FileFetchers
    class Base
      def _fetch_file_content(path, fetch_submodules: false)
        if Pathname.new(path).exist?
          File.open(path, 'r') do |f|
            f.read
          end
        else
          raise Dependabot::DependencyFileNotFound, path
        end
      end

      def fetch_file_if_present(path, type: "file", fetch_submodules: false)
        fullPath = File.join(REPO_DIRECTORY, path)
        fetch_file_from_host(path, fetch_submodules: fetch_submodules) if Pathname.new(fullPath).exist?
      end

      def _fetch_repo_contents(path, raise_errors: true, fetch_submodules: false)
        base_dir = File.join(REPO_DIRECTORY, path)
        Dir['*', base: base_dir].map do |file|
          type = File.file?(File.join(base_dir, file)) ? 'file' : 'dir'
          FileStruct.new(file, base_dir, type, 0)
        end
      end
    end
  end
end
####### END Monkey patch

Source           = Struct.new(:provider, :directory)
DependencyUpdate = Struct.new(:name, :ignore_versions, :commit_message)

git    = Git.open(REPO_DIRECTORY)
config = YAML.load(File.read("config.yml"))

PACKAGE_MANAGER = config["package_manager"]

dependency_updates = config["dependency_updates"].map do |dependency_update|
  DependencyUpdate.new(dependency_update["name"], dependency_update["ignore_versions"], dependency_update["commit_message"])
end

def updateDependency(dependency_name, ignore_versions)
  puts "Updating #{dependency_name}.  Ignoring versions #{ignore_versions}"

  credentials = []
  source = Source.new('file_system', REPO_DIRECTORY)

  #############################
  # Fetch the dependency files #
  #############################
  fetcher = Dependabot::FileFetchers.for_package_manager(PACKAGE_MANAGER).
            new(source: source, credentials: credentials)

  files = fetcher.files

  #############################
  # Parse the dependency files #
  #############################
  parser = Dependabot::FileParsers.for_package_manager(PACKAGE_MANAGER).new(
    dependency_files: files,
    source: source,
    credentials: credentials,
  )

  dependencies = parser.parse
  dep = dependencies.find { |d| d.name == dependency_name }

  #########################################
  # Get update details for the dependency #
  #########################################
  checker = Dependabot::UpdateCheckers.for_package_manager(PACKAGE_MANAGER).new(
    dependency: dep,
    dependency_files: files,
    credentials: credentials,
    ignored_versions: [ignore_versions]
  )

  updated_deps = checker.updated_dependencies(requirements_to_unlock: :own)

  #####################################
  # Generate updated dependency files #
  #####################################
  updater = Dependabot::FileUpdaters.for_package_manager(PACKAGE_MANAGER).new(
    dependencies: updated_deps,
    dependency_files: files,
    credentials: credentials,
  )

  begin
    updated_files = updater.updated_dependency_files
  rescue Dependabot::NpmAndYarn::FileUpdater::NoChangeError
    puts "    SKIPPING #{dependency_name} since no updates were found."
    return false
  end

  updated_files.each do |file|
    path = REPO_DIRECTORY + '/' + file.name
    puts "    - Updating #{path}"

    File.open(path, 'w') do |f|
      f.write(file.content)
    end
  end

  return true
end

dependency_updates.each do |dependency|
  updatedFiles = updateDependency(dependency.name, dependency.ignore_versions)

  if updatedFiles
    git.add
    git.commit(dependency.commit_message)
  end
end

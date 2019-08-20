require "dependabot/file_fetchers"
require "dependabot/file_parsers"
require "dependabot/update_checkers"
require "dependabot/file_updaters"
require "dependabot/omnibus"

require "pathname"
require "yaml"
require 'rubygems'
require 'git'



####### Monkey patching to get reading source files from disk
module Dependabot
  module NpmAndYarn
    class FileFetcher
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
        fullPath = '/service/repo/' + path
        fetch_file_from_host(path, fetch_submodules: fetch_submodules) if Pathname.new(fullPath).exist?
      end
    end
  end
end
####### END Monkey patch

# Directory where the base dependency files are.
REPO_DIRECTORY = "/service/repo"
PACKAGE_MANAGER = "npm_and_yarn"

Dependency = Struct.new(:name, :ignore_versions, :commit_message)

config = YAML.load(File.read("config.yml"))

dependencies = config.map do |(name, ignore_versions, commit_message)|
  Dependency.new(name, ignore_versions, commit_message)
end

git = Git.open('/service/repo')

class Source
  attr_accessor :provider, :repo, :directory, :branch

  def initialize(provider, directory)
    @provider = provider
    @repo = nil
    @directory = directory
    @branch = nil
  end
end

def updateDependency(dependency_name, ignore_versions)
  puts "Updating #{dependency_name}.  Ignoring versions #{ignore_versions}"

  credentials = []
  source = Source.new('local', REPO_DIRECTORY)

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

  checker.up_to_date?
  checker.can_update?(requirements_to_unlock: :own)
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

dependencies.each do |dependency|
  updatedFiles = updateDependency(dependency.name, dependency.ignore_versions)

  if updatedFiles
    git.add
    git.commit(dependency.commit_message)
  end
end

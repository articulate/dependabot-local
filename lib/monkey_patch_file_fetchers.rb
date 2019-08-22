require_relative './constants.rb'

FileStruct = Struct.new(:name, :path, :type, :size)

# Monkey patching FileFetchers to read source files from disk
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
        fullPath = File.join(Constants::REPO_DIRECTORY, path)
        fetch_file_from_host(path, fetch_submodules: fetch_submodules) if Pathname.new(fullPath).exist?
      end

      def _fetch_repo_contents(path, raise_errors: true, fetch_submodules: false)
        base_dir = File.join(Constants::REPO_DIRECTORY, path)
        Dir['*', base: base_dir].map do |file|
          type = File.file?(File.join(base_dir, file)) ? 'file' : 'dir'
          FileStruct.new(file, base_dir, type, 0)
        end
      end
    end
  end
end

require "pathname"

module Librarian
  module GemSpec
    def self.FileFinder(gem_root, excludes)
      FileFinder.create(gem_root, excludes)
    end

    class FileFinder

      class << self
        attr_accessor :subclasses
        private :subclasses=
        private_class_method :new
        def inherited(subclass)
          subclasses << subclass
          subclass.instance_exec do
            public_class_method :new
          end
        end
        def create(gem_root, excludes = [])
          gem_root = find_gem_root(gem_root)
          subclass = subclasses_for(gem_root).first
          subclass or raise StandardError, "no suitable file-finder"
          subclass.new(gem_root, excludes)
        end
      private
        def find_gem_root(gem_root)
          gem_root = Pathname(gem_root)
          gem_root = gem_root.dirname if gem_root.extname == ".gemspec"
          gem_root
        end
        def subclasses_for(gem_root)
          subclasses.select{|klazz| klazz.pass?(gem_root)}
        end
      end
      self.subclasses = []

      class Git < self
        def self.pass?(gem_root)
          gem_root.join(".git").exist?
        end
      private
        def ls_files(*paths)
          command = "ls-files"
          command << " -- {#{paths.join(',')}}/*" unless paths.empty?
          Dir.chdir(gem_root){`git #{command}`}.lines.to_a
        end
      end

      class Default < self
        def self.pass?(gem_root)
          true
        end
      private
        def ls_files(*paths)
          paths << "" if paths.empty?
          paths.map{|p| includable_paths(p)}.flatten(1)
        end
        def includable_glob(path)
          gem_root.join(path).join("**/*")
        end
        def includable_paths(path)
          glob = includable_glob(path).to_s
          Dir.glob(glob, File::FNM_PATHNAME | File::FNM_DOTMATCH)
        end
      end

      attr_reader :gem_root , :excludes
      def initialize(gem_root, excludes = [])
        self.gem_root = gem_root
        self.excludes = excludes
      end
      def files
        clean{ls_files}
      end
      def test_files
        clean{ls_files("spec", "features")}
      end
      def executables
        clean{ls_files("bin")}.map{|f| File.basename(f)}
      end

    private

      attr_writer :gem_root, :excludes
      def clean
        always_relative(without_excludables(yield)).map(&:to_s).uniq.sort
      end
      def always_relative(list)
        list.map{|e| e = Pathname(e) ; e.relative? ? e : e.relative_path_from(gem_root)}
      end
      def without_excludables(list)
        list.reject{|p| excludable_path?(p)}
      end
      def relative_excludable_globs
        @relative_excludable_globs ||= excludes.map{|p| Pathname(p).join("**/*").to_s}
      end
      def absolute_excludable_globs
        @absolute_excludable_globs ||= relative_excludable_globs.map{|g| gem_root.join(g).to_s}
      end
      def always_excludables
        @always_excludables ||= %w(. ..)
      end
      def excludable_path?(path)
        path = Pathname(path) unless Pathname === path
        return true if always_excludables.include?(path)
        return true unless path.file?
        excludable_globs = path.absolute? ? absolute_excludable_globs : relative_excludable_globs
        excludable_globs.any? do |glob|
          path.fnmatch?(glob, File::FNM_PATHNAME | File::FNM_DOTMATCH)
        end
      end

    end
  end
end

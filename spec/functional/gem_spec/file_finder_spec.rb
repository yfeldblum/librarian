require "securerandom"

require "librarian/gem_spec/file_finder"

module Librarian
  module GemSpec
    describe FileFinder do

      def gemspec_path_for(path) Pathname.glob(path.join("*.gemspec")).first end
      def sys_root?(path) path.dirname == path end
      def gem_root?(path) gemspec_path_for(path) end

      let(:gem_root) do
        path = Pathname(__FILE__)
        path = path.dirname until gem_root?(path) || sys_root?(path)
        path
      end
      let(:gemspec_path) { gemspec_path_for(gem_root) }
      let(:excludes) { %w(.*/* pkg tmp) }
      let(:tmp) { gem_root.join("tmp") }
      let(:rfile) { "lib/librarian.rb" }
      let(:tfile) { "tmp/#{SecureRandom.hex(16)}.tmp" }
      before { tmp.mkpath unless tmp.exist? }
      before { gem_root.join(tfile).open("wb"){|f| f.write(tfile)} }
      after  { gem_root.join(tfile).delete }

      context "finding the right file-finder" do

        it "should find the git file-finder" do
          finder = GemSpec::FileFinder(gemspec_path, excludes)
          finder.should be_kind_of FileFinder::Git
        end

        it "should find the default file-finder" do
          finder = GemSpec::FileFinder(gem_root.join("lib"), excludes)
          finder.should be_kind_of FileFinder::Default
        end

      end

      describe FileFinder::Default do
        subject { FileFinder::Default.new(gem_root, excludes) }

        it "should include the real file" do
          subject.files.should include rfile
        end

        it "should not include the temp file" do
          subject.files.should_not include tfile
        end

        it "should return only strings" do
          subject.files.map(&:class).uniq.should == [String]
        end

        it "should not include ." do
          subject.files.should_not include "."
        end

        it "should include .gitignore" do
          subject.files.should include ".gitignore"
        end
      end

      describe FileFinder::Git do
        subject { FileFinder::Default.new(gem_root, excludes) }

        it "should include the real file" do
          subject.files.should include rfile
        end

        it "should not include the temp file" do
          subject.files.should_not include tfile
        end

        it "should return only strings" do
          subject.files.map(&:class).uniq.should == [String]
        end

        it "should not include ." do
          subject.files.should_not include "."
        end

        it "should include .gitignore" do
          subject.files.should include ".gitignore"
        end
      end

      describe "the gemspec" do
        it "should kernel-load" do
          load gemspec_path.to_s
        end

        it "should gemspec-load" do
          gemspec = Gem::Specification.load(gemspec_path.to_s)
          gemspec.should_not be_nil
        end
      end

    end
  end
end

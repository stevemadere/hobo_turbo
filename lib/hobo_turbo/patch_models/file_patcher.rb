module HoboTurbo
  module PatchModels
    require 'pathname'
    require 'fileutils'
    require 'tempfile'

    class FilePatcher
      def initialize(fname)
        @filename = fname
        raise "Cannot patch #{filename} because it does not exist!" unless File.exist?(filename)
        @content = @orig_content = File.readlines(filename)
      end

      attr_reader :orig_content, :filename
      attr_accessor :content

      def first_line_matching(regex)
        orig_content.index {|line| line =~ regex}
      end

      def last_line_matching(regex)
        orig_content.rindex {|line| line =~ regex}
      end

      def commit!
        pn = Pathname.new(filename).realpath
        dirname = pn.dirname
        basename = pn.basename
        # This is not working. Not sure why
        #tempfile = Tempfile.new(basename,dirname)
        tf_name = filename + ".patching"
        tempfile = File.open(tf_name,"w")
        tempfile.write(content.join);
        tempfile.close
        File.rename(tf_name,filename)
      end
    end
  end
end

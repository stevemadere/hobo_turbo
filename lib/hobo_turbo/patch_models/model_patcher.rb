module HoboTurbo
  module PatchModels
    require 'active_support/inflector'

    class ModelPatcher
      def initialize(subject,object)
        @subject = subject
        @object = object
        @has_inverse = true
        @relationship = nil # subclasses will need to set this in their constructor
        @file_patcher ||= FilePatcher.new(model_file)
      end

      attr_reader :file_patcher
      attr_accessor :has_inverse

      def association_line_regex(relationship, object)
        /^\s*\b#{relationship}\s+:#{object}\b/
      end

      def attr_accessible_index
        @attr_accessible_index ||= file_patcher.last_line_matching(/^\s*\battr_accessible\s+/)
      end

      def attr_accessible_line
        file_patcher.content[attr_accessible_index]
      end

      def attr_accessible_line=(new_value)
        file_patcher.content[attr_accessible_index] = new_value
      end


      def commit!
          file_patcher.commit!
      end

      def compose_association_statement
        direct_association_statement
      end

      def insert_after_accessible(new_line)
          file_patcher.content.insert(attr_accessible_index+1,new_line)
      end

      def inverse_association
        @subject
      end

      def leading_whitespace
          if @leading_whitespace.nil?
            @leading_whitespace = ''
            if attr_accessible_line =~ /^(\s+)attr_accessible\b/
              @leading_whitespace = $1
            end
          end
          return @leading_whitespace
      end

      def make_accessible(member)
        old_attr_accessible_line = file_patcher.content[attr_accessible_index]
        if attr_accessible_line =~ /:#{member}\b/
          puts "#{member} is alreay accessible in #{@subject}"
          return
        end
        separator = (attr_accessible_line =~ /^\s*attr_accessible\s*$/) ? " " :  ", "
        new_attr_accessible_line = attr_accessible_line.chomp + separator + ":#{member}\n"
        puts "replacing #{attr_accessible_line} with #{new_attr_accessible_line}"
        self.attr_accessible_line = new_attr_accessible_line
      end

      def model_file
        @model_file ||= "app/models/#{@subject}.rb"
      end

      def patch
        relationship_regex = association_line_regex(@relationship, @object)
        if file_patcher.first_line_matching(relationship_regex )
          puts "#{@subject} already has an association to #{@object}"
          return
        else
          if attr_accessible_index.nil?
            raise "could not find attr_accessible directive in #{model_file}"
          end
          puts "adding #{@object} association to #{@subject}"
          make_accessible(@object)
          association_line = compose_association_statement
          puts "adding #{association_line}"
          insert_after_accessible(association_line)
        end
      end

      def direct_association_statement
        "#{leading_whitespace}#{@relationship} :#{@object}" +
          (@has_inverse ?   ", :inverse_of => :#{inverse_association}\n" : "\n")
      end

      def indirect_association_statement
          "#{leading_whitespace}#{@relationship} :#{@object}, :through => :#{@intermediate}\n"
      end

      def require_association_to_intermediate(relationship)
        regex = association_line_regex(relationship, @intermediate)
        matching_index = file_patcher.orig_content.index {|line| line =~ regex}
        raise "cannot add an association to #{@object} through #{@intermediate} without first adding an association for #{@intermediate}" unless matching_index
      end

    end

    class BelongsToPatcher < ModelPatcher
      def initialize(subject,object)
        super
        @relationship = :belongs_to
      end

      def patch
        super
        make_accessible("#{@object}_id")
      end

      def inverse_association
        @subject.pluralize
      end
    end

    class BelongsToThroughPatcher < BelongsToPatcher
      def initialize(subject,object,intermediate)
        super(subject,object)
        @intermediate = intermediate
        check_prerequesites
      end

      def check_prerequesites
        require_association_to_intermediate(:belongs_to )
      end

      def compose_association_statement
        indirect_association_statement
      end

    end

    class HasManyPatcher < ModelPatcher
      def initialize(subject,object)
        super
        @relationship = :has_many
      end
    end

    class HasManyThroughPatcher < HasManyPatcher
      def initialize(subject,object,intermediate)
        super(subject,object)
        @intermediate = intermediate
        check_prerequesites
      end

      def check_prerequesites
        require_association_to_intermediate(:has_many)
      end

      def compose_association_statement
        indirect_association_statement
      end

    end


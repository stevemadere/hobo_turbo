

module HoboTurbo
  # Model helpers to implement Hobo permissions which are delegated
  # to a member (typically considered a parent).  e.g. In a model that
  # has a parent model, if the acting_user is allowed to modify the
  # parent, then they are allowed to create, destroy, and edit the
  # child.
  #
  # Include this module in any model which has a 'belongs_to :parent_model'
  # statement in it.  Then, call the following class method:
  #
  #  delegate_permissions_to :parent_model
  #
  # This results in the following permissions enforcement:
  # Anyone who can edit the some_other_model member can:
  #   Create child instances of this model
  #   Destroy child instances of this model
  #   Edit chld instances of this model
  #
  # If you define a method called self.class.immutable_fields in your
  # model, the update permissions will be adjusted accordingly.
  # e.g. this definition:
  #     def self.class.immutable_fields ; [:parent,:coinventor] ; end
  # Results in updates being forbidden for the parent or coinventor fields.
  #
  module DelegatedPermissions

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      # Creates Hobo permissions methods that delegate create, update, and
      # destroy permissions regulation to the parent object.
      def delegate_permissions_to(parent)
        self.class_eval <<-"METHODEND"
          def create_permitted?
            delegate = self.send('#{parent}')
            delegate.nil? || delegate.new_record? || delegate.updatable_by?(acting_user)
          end
        METHODEND

        ['update_permitted?','destroy_permitted?'].each do |m|
          define_method(m) do |*args|
            self.create_permitted?
          end
        end
      end
    end
  end
end

module HoboTurbo
  # Model helpers to handle standard permission pattern for user-owned
  # publicly viewable content
  #
  # Include this module in any model which has a 'belongs_to :user'
  # statement in it and which follows a conventional permissions model:
  # * Only signed_up users can create
  # * Only the owner or an administrator can update or delete
  #
  # If you define a method called self.class.immutable_fields in your
  # model, the update permissions will be adjusted accordingly.
  # e.g. this definition:
  #     def self.class.immutable_fields ; [:parent,:coinventor] ; end
  # Results in updates being forbidden for the parent or coinventor fields.
  #
  module UserOwnedPermissions

    def create_permitted?
      return true if acting_user.administrator?
      acting_user.signed_up? && ((!user) || user_is?(acting_user))
    end

    def update_permitted?
      return true if acting_user.administrator?
      if user
        return false unless (user_is?(acting_user) && !user_changed?)
      end
      if self.class.respond_to?(:immutable_fields)
        return false if any_changed?(*self.class.immutable_fields)
      end
      return true
    end

    def destroy_permitted?
      return true if acting_user.administrator?
      user_is?(acting_user)
    end

    def view_permitted?(field)
      true
    end

  end
end

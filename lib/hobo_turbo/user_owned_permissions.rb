module HoboTurbo
  # Model helpers to handle standard permission pattern for user-owned
  # publicly viewable content
  #
  # Include this module in any model which has a 'belongs_to :user'
  # statement in it and which follows a conventional permissions model:
  # * Only signed_up users can create
  # * Only the owner or an administrator can update or delete
  #
  # If the member referring to the owner is not named :user, you
  # can define a method called owner_member to indicate that.
  # e.g. If instead of user, your member that refers to the owner is
  # called custodian, you would put this in your model:
  #   def owner_member
  #     custodian
  #   end
  #
  # If you define a method called self.class.immutable_fields in your
  # model, the update permissions will be adjusted accordingly.
  # e.g. this definition:
  #     def self.class.immutable_fields ; [:parent,:coinventor] ; end
  # Results in updates being forbidden for the parent or coinventor fields.
  #
  module UserOwnedPermissions

    def owner_member
      user
    end

    def owner_member_is?(u)
      u && owner_member && (u.id == owner_member.id)
    end

    def create_permitted?
      return true if acting_user.administrator?
      acting_user.signed_up? && ((!owner_member) || owner_member_is?(acting_user))
    end

    def update_permitted?
      return true if acting_user && acting_user.administrator?
      return false unless (owner_member && owner_member_is?(acting_user) && !user_changed?)

      if self.class.respond_to?(:immutable_fields)
        return false if any_changed?(*self.class.immutable_fields)
      end
      return true
    end

    def destroy_permitted?
      return true if acting_user.administrator?
      owner_member && owner_member_is?(acting_user)
    end

    def view_permitted?(field)
      true
    end

  end
end

require 'minitest/autorun'
require 'hobo_turbo/delegated_permissions'
require 'active_support/hash_with_indifferent_access'
# These are fixture classes.
# I should really be using mocks but I just cannot get mocha to
# work with Test::Unit  (gem version dependency hell)
class Parent
  require 'set'

  def initialize
    @calls_made = Hash.new {|h,k| h[k]=[]}
    @allowed_users = Set.new
  end

  attr_reader :calls_made

  def new_record?
    false
  end

  def allow_update_by(user)
    @allowed_users.add(user)
  end

  def updatable_by?(u)
    @calls_made['updatable_by?'] << [u]
    @allowed_users.include?(u)
  end

  def method_missing(m,*args)
    puts "called #{m}"
    @calls_made[m] << args
    true
  end

end

class Child
   include HoboTurbo::DelegatedPermissions
   attr_accessor :parent
   attr_accessor :acting_user

   delegate_permissions_to :parent
end

class DelegatedPermissionsTestCase < Minitest::Test

  def test_smoke
    child = Child.new
    parent = Parent.new
    child.parent = parent
    acting_user = 'the user'
    child.acting_user = acting_user

    child.create_permitted?
    child.update_permitted?
    child.destroy_permitted?

  end

  def test_create_permitted
    child = Child.new
    parent = Parent.new
    child.parent = parent
    allowed_user = 'owning user'
    non_allowed_user = 'another user'
    parent.allow_update_by(allowed_user)

    child.acting_user = allowed_user
    should_be_allowed = child.create_permitted?
    assert_equal(1,parent.calls_made['updatable_by?'].size)
    assert_equal([child.acting_user] ,parent.calls_made['updatable_by?'][0])
    assert_equal(true,should_be_allowed)

    child.acting_user = non_allowed_user
    should_be_allowed = child.create_permitted?
    assert_equal(2,parent.calls_made['updatable_by?'].size)
    assert_equal([child.acting_user] ,parent.calls_made['updatable_by?'][1])
    assert_equal(false,should_be_allowed)
  end

end

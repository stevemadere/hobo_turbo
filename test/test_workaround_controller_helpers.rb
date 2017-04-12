require 'minitest/autorun'
require 'active_support/hash_with_indifferent_access'
require 'ostruct'
require 'hobo_turbo/workarounds/controller_helpers'

# These are fixture classes.
# I should really be using mocks but I just cannot get mocha to
# work with Test::Unit  (gem version dependency hell)
class User < OpenStruct
  @@id_serial = 1
  @@ignored_on_create = HashWithIndifferentAccess.new
  def initialize(*args)
    super
    @id = nil
  end

  def self.refuse_to_assign_on_create(*attribute_names)
    @@ignored_on_create.clear
    attribute_names.each do |attribute_name|
      @@ignored_on_create[attribute_name] = 1
    end
  end

  def self.next_id
    @@id_serial+=1
  end

  def new_record?
    @id.nil?
  end

  def save
    @id ||= self.class.next_id
  end

  def self.create(attributes)
    used_attributes  = {}
    attributes.each_pair do |k,v|
      used_attributes[k] = v unless @@ignored_on_create.include?(k)
    end
    self.new(used_attributes)
  end

  def update_attributes(attributes)
    attributes.each_pair do |k,v|
      self.send("#{k}=",v) unless new_record? && @@ignored_on_create.include?(k)
    end
  end
end

class UsersController

  include HoboTurbo::Workarounds::ControllerHelpers

  def initialize()
    @params = {}
    @this = nil
  end

  attr_accessor :params
  attr_reader :this

  def hobo_do_signup
    @this = User.create(params[:user])
  end

end

class WorkaroundControlllerHelpersTestCase < Minitest::Test
  include HoboTurbo::Workarounds::ControllerHelpers

  def test_user_class_fixture
    User.refuse_to_assign_on_create(:foo)
    name_val = 'bob'
    foo_val = [1,2,3]
    u = User.create({name:name_val, foo: foo_val})
    assert_equal(name_val, u.name)
    assert_nil(u.foo)
  end

  def test_users_controller_class_fixture
    controller = UsersController.new
    User.refuse_to_assign_on_create(:allergies)

    # Ensure that if we do not use the workaround, our mocked Controller
    # and User combo does the same stupid thing the real Controller 
    # and User would (fail to assign the allergies attribute)
    allergy_ids = [ 2, 3, 4]
    controller.params = { user: { name: 'joe', allergies: allergy_ids } }
    controller.hobo_do_signup
    assert_equal('joe', controller.this.name)
    assert_nil(controller.this.allergies)
  end

  def test_no_deferred_attribute
    UsersController.class_eval <<-'EOEVAL'
      def do_signup
        do_signup_with_deferred_attributes
      end
    EOEVAL

    User.refuse_to_assign_on_create(:allergies)

    allergy_ids = [ 2, 3, 4]

    controller = UsersController.new
    controller.params = { user: { name: 'joe', allergies: allergy_ids } }
    controller.do_signup
    assert_equal('joe',controller.this.name)
    assert_equal(nil,controller.this.allergies)

  end

  def test_one_deferred_attribute
    UsersController.class_eval <<-'EOEVAL'
      def do_signup
        do_signup_with_deferred_attributes(:allergies)
      end
    EOEVAL

    User.refuse_to_assign_on_create(:allergies)

    allergy_ids = [ 2, 3, 4]

    controller = UsersController.new
    controller.params = { user: { name: 'joe', allergies: allergy_ids } }
    controller.do_signup
    assert_equal('joe',controller.this.name)
    assert_equal(allergy_ids,controller.this.allergies)

  end

  def test_two_deferred_attribute
    UsersController.class_eval <<-'EOEVAL'
      def do_signup
        do_signup_with_deferred_attributes(:allergies, :siblings)
      end
    EOEVAL

    User.refuse_to_assign_on_create(:allergies)

    allergy_ids = [ 2, 3, 4]
    sibling_ids = [ 8, 9, 10]

    controller = UsersController.new
    controller.params = { user: { name: 'joe', allergies: allergy_ids, siblings: sibling_ids } }
    controller.do_signup
    assert_equal('joe',controller.this.name)
    assert_equal(allergy_ids,controller.this.allergies)
    assert_equal(sibling_ids,controller.this.siblings)

  end


end

require 'minitest/autorun'
require 'hobo_turbo/autocomplete_helpers'
require 'active_support/hash_with_indifferent_access'

# These are fixture classes.
# I should really be using mocks but I just cannot get mocha to
# work with Test::Unit  (gem version dependency hell)
class Model
  def initialize(name)
    @name = name
  end
  attr_accessor :name

  protected
    def self.find_or_create_by_name(n)
      instances_by_name[n] ||= self.new(n)
    end
end

class City < Model
  @@cities = {}

  def self.instances_by_name
     @@cities
  end

  def self.lookup_by_name(n)
    find_or_create_by_name(n)
  end
end

class State < Model
  @@states = {}

  def self.instances_by_name
     @@states
  end

  def self.find_by_name(n)
    find_or_create_by_name(n)
  end
end


class AutocompleteHelpersRepairParamsTestCase < Minitest::Test
  include HoboTurbo::AutocompleteHelpers

  def test_smoke
    city_model = City
    city_name = "Chicago"
    city_object = City.lookup_by_name(city_name)
    not_a_model_class = Hash.new
    params = {user_profile: { city: city_name } }
      repair_association_autocomplete_params(params[:user_profile],:city,city_model)

    assert_raises(NoMethodError) {
      repair_association_autocomplete_params(params[:user_profile],:city, not_a_model_class)
    }

  end

  def test_lookup_by_name
    city_model = City
    city_name = "Chicago, IL, USA"
    city_object = City.lookup_by_name(city_name)
    params = {user_profile: { city: city_name } }
      repair_association_autocomplete_params(params[:user_profile],:city,city_model)
    assert_equal(city_object,params[:user_profile][:city])
  end

  def test_find_by_name
    state_model = State
    state_name = "Texas"
    state_object = State.find_by_name(state_name)
    params = {user_profile: { state: state_name } }
      repair_association_autocomplete_params(params[:user_profile],:state,state_model)
    assert_equal(state_object,params[:user_profile][:state])
  end

  def test_infer_model
    city_model = City
    city_name = "Chicago, IL, USA"
    city_object = City.lookup_by_name(city_name)
    params = {user_profile: { city: city_name } }
      repair_association_autocomplete_params(params[:user_profile],:city)
    assert_equal(city_object,params[:user_profile][:city])
  end

  def test_wrong_member_name
    city_model = City
    city_name = "Chicago, IL, USA"
    city_object = City.lookup_by_name(city_name)
    params = {user_profile: { city: city_name } }
    wrong_member_name = :county
      repair_association_autocomplete_params(params[:user_profile],wrong_member_name,city_model)
    assert(!params[:user_profile].include?(wrong_member_name), "Should not add missing parameters.")
  end


end

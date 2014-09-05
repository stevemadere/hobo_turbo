require 'active_support/inflector'
module HoboTurbo
  # Controller helpers to ease the use of the Hobo <autocomplete> tag
  module AutocompleteHelpers
    # A utility method to ease the use of Hobo autocomplete on belongs_to associations.
    # Modifies a param if necessary to make a subsequent update or create
    # action work properly with a member that came from a string-based
    # autoocomplete of the name of the associated object.
    #
    # Example scenario: Our model UserProfile has an association
    # "belongs_to :city" and we want to autocomplete the city name in a form 
    # and then use that name to look up the corresponding City to populate
    # the city member of UserProfile
    #
    # +param_for_object+:  The actual member of params[] (not a copy) for the object being updated e.g. params[:user_profile].  This will be modified.
    # +member_name+: The name of the association of the object that is autocompleted. e.g. :city
    # +class_of_association+: The class (model) of the target of the association that is autocompleted. e.g. City.  Defaults to member_name.classify.constantize.  If this class implements a lookup_by_name method(objname) method, that will be used, otherwise find_by_name(objname) will be used.
    #
    # ==== Example usage:
    #   class UserProfilesController < ApplicationController
    #     hobo_model_controller
    #     include HoboTurbo::AutocompleteHelpers
    #     def update
    #       repair_association_autocomplete_params(params[:user_profile],:city,City)
    #       hobo_update
    #     end
    #
    #     def create
    #       repair_association_autocomplete_params(params[:user_profile],:city,City)
    #       hobo_create
    #     end
    #   end
    #
    #  Corresponding form dryml:
    #     <field-list fields="city, ....">
    #       <city-view:>
    #         <autocomplete source="&City.find(:all,limit:5000).map {|c| c.name}" />
    #       </city-view:>
    #        ...
    #     </field-list>
    #
    def repair_association_autocomplete_params(param_for_object, member_name, class_of_association=nil)
      if class_of_association.nil?
        class_of_association = member_name.to_s.classify.constantize
        $stderr.puts "inferred class_of_association #{class_of_association.name}"
        raise "You must specify class_of_association parameter unless it can be obviously inferred from the member name" unless class_of_association.respond_to?(:lookup_by_name) || class_of_association.respond_to?(:find_by_name)
      end
      return nil unless param_for_object.include?(member_name) # do not add new fields if they don't exist

      # This metod handles 3 different member parameter scenarios:
      # 1.  member is already a serialized class_of_association object
      # 2.  member is a nested hash with just a name:  [member_name][member_name]
      # 3.  member is a string containing a name
      if (!param_for_object[member_name].respond_to?(:keys)) || param_for_object[member_name].keys.all? {|k| k.to_s.downcase == member_name.to_s.downcase }
        # Scenarios 2 and 3 require converson to an object
        object_name =  param_for_object[member_name].respond_to?(:keys) ?  param_for_object[member_name][member_name] : param_for_object[member_name]
        actual_object = class_of_association.lookup_by_name(object_name) rescue class_of_association.find_by_name(object_name)
        param_for_object[member_name] = actual_object
      end
    end
  end
end

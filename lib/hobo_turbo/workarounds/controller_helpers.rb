require 'active_support/inflector'
module HoboTurbo
  # Utilities to work around bugs in Rails or Hobo
  module Workarounds
  # Controller helpers to work around bugs in Rails or Hobo
    module ControllerHelpers
=begin rdoc
A workaround that allows mass assignment to a has_many association
in a signup controller action.

Defers assigment of the specified attributes until after the main
record has been saved (so that it will have an id that can be used
in the external references of the has_many relationship).

====== Example scenario:
Our model User has this association declaration:

  has_many :allergies :through :user_allergies
  
and we want to mass assign the +allergies+ attribute during signup.

== Arguments
- *+deferred_attribute_names+: A list of attribute names whose mass assisgnment should be deferred until after creation of the owner object.

==== Example usage:

   class UsersController < ApplicationController
     hobo_user_controller
     include HoboTurbo::Workarounds::ControllerHelpers

     def do_signup
       do_signup_with_deferred_attributes(:allergies)
     end
   end
        
=end
      def do_signup_with_deferred_attributes(*deferred_attribute_names)
        deferred_attributes = {}
        deferred_attribute_names.each do |pname|
          v = params[:user].delete(pname)
          if v.nil?
            deferred_attributes.delete(pname)
          else
            deferred_attributes[pname]  = v
          end
        end

        hobo_do_signup
        if deferred_attributes.values.any? {|v| !v.nil? }
          this.save if this.new_record?
          this.update_attributes(deferred_attributes)
        end
      end
    end
  end
end

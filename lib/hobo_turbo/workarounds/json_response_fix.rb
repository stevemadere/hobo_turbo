module HoboTurbo
  # Utilities to work around bugs in Rails or Hobo
  module Workarounds
=begin rdoc
  A workaround for a bug in hobo_controller response logic that
  breaks the normal respond_to :json behavior.

  This workaround auto-creates *_response methods that explicitly
  handle json requests by rendering self.this as json.

  Just specify respond_to :json, :html and include JsonResponseFix
  in your controller after the call to hobo_controller
          
=end
    module JsonResponseFix
      def self.included(base)
        actions = [:index,:show,:create, :update, :destroy]
        actions.each do |action|
          response_method = (action.to_s + "_response").to_sym
          base.class_eval <<-"METHODEND"
            def #{response_method}(*args)
              respond_to do |format|
                format.html do
                  super
                end
                format.json do
                  render json: self.this
                end
              end
            end
          METHODEND
        end
      end
    end
  end
end

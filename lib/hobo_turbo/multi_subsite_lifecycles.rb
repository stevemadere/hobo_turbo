#  A monkeypatch to allow hobo lifecycles to be auto-routed in
#  multiple subsites or all subsites by default
module Hobo
  module Model
    module Lifecycles
      module Actions
        def routable_for?(subsite)
          publishable? && (!options.include?(:subsite)) || options[:subsite] == subsite || (options[:subsites] && options[:subsites].include?(subsite))
        end
        
      end
    end
  end
end
  
module MultiSubsiteLifecycles
end

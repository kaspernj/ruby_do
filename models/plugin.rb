class Ruby_do::Models::Plugin < Knj::Datarow
  has_many [
    {:class => :Static_result, :autodelete => true}
  ]
  
  attr_accessor :plugin
end
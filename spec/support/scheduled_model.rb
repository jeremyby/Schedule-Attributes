require 'schedule_attributes'

class ScheduledModel
  include ScheduleAttributes
  attr_accessor :schedule_yaml
end

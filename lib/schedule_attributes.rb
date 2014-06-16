require 'ice_cube'
require 'active_support'
require 'active_support/time_with_zone'
require 'ostruct'

module ScheduleAttributes
  # Your code goes here...
  DAY_NAMES = Date::DAYNAMES.map(&:downcase).map(&:to_sym)
  
  def schedule
    @schedule ||= begin
      if schedule_hash.blank?
        IceCube::Schedule.new(Time.now.utc).tap{|sched| sched.add_recurrence_rule(IceCube::Rule.daily) }
      else
        IceCube::Schedule.from_hash(schedule_hash)
      end
    end
  end

  def schedule_attributes=(options)
    options = options.dup
    options[:interval] = options[:interval].to_i
    options[:start_time] &&= ScheduleAttributes.parse_in_timezone(options[:start_time])
    options[:until_time] &&= ScheduleAttributes.parse_in_timezone(options[:until_time])

    @schedule = IceCube::Schedule.new(options[:start_time])

    rule = case options[:interval_unit]
      when 'day'
        IceCube::Rule.daily options[:interval]
      when 'week'
        IceCube::Rule.weekly(options[:interval]).day( *IceCube::DAYS.keys.select{|day| options[day].to_i == 1 } )
    end

    rule.until(options[:until_time]) unless options[:until_time].blank?

    @schedule.add_recurrence_rule(rule)

    self.schedule_hash = @schedule.to_hash
  end

  def schedule_attributes
    atts = {}

    rule = schedule.rrules.first
    atts[:start_time] = schedule.start_time

    rule_hash = rule.to_hash
    atts[:interval] = rule_hash[:interval]

    case rule
    when IceCube::DailyRule
      atts[:interval_unit] = 'day'
    when IceCube::WeeklyRule
      atts[:interval_unit] = 'week'
      rule_hash[:validations][:day].each do |day_idx|
        atts[ DAY_NAMES[day_idx] ] = 1
      end
    end

    if rule.until_time
      atts[:until_time] = rule.until_time
      atts[:ends] = 'eventually'
    else
      atts[:ends] = 'never'
    end

    OpenStruct.new(atts)
  end

  # TODO: test this
  def self.parse_in_timezone(str)
    if Time.respond_to? :zone
      Time.zone.parse(str)
    else
      Time.parse(str)
    end
  end
end

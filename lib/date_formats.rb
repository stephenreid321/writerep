require 'active_support/core_ext/integer/inflections'

Time::DATE_FORMATS.merge!(
  :default => lambda { |time| time.to_s(:date) + ', ' + time.to_s(:time) },
  :date => lambda { |time| time.to_date.to_s },
  :time => lambda { |time| time.strftime("#{(t = time.hour%12) == 0 ? 12 : t}:%M#{time.strftime('%p').downcase}") }
)

Date::DATE_FORMATS.merge!(
  :default => lambda { |date| date.strftime("%a #{date.day.ordinalize} %b %Y") }
)
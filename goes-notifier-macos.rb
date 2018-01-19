#!/usr/bin/env ruby
require 'json'
require 'date'
require 'httparty'
require 'terminal-notifier'

BASE_URL = "https://ttp.cbp.dhs.gov/schedulerapi/slots?orderBy=soonest&limit=1&locationId=%s&minimum=1"

def notify_earlier_appt(date)
  TerminalNotifier.notify(
    'There is an earlier spot open!',
    :title => 'Global Entry',
    :subtitle => date.strftime('%m/%d/%Y'),
    :open => 'https://secure.login.gov')
end

def run(current_appt_date, location_id, interval)
  puts "Looking for appointments sooner than #{current_appt_date.strftime('%m/%d/%Y')} at location #{location_id} every #{interval} seconds"
  earliest_appt = Date.parse('2020-12-31')
  while earliest_appt > current_appt_date
    response = HTTParty.get(BASE_URL % [location_id])
    if response.count > 0
      response = JSON.parse response.body, symbolize_names: true
      earliest_appt = Date.parse(response[0][:startTimestamp])
      notify_earlier_appt(earliest_appt) if earliest_appt < current_appt_date
      puts "Your appointment (#{current_appt_date.strftime('%m/%d/%Y')}) is still before the earliest available appointment (#{earliest_appt.strftime('%m/%d/%Y')})" unless earliest_appt < current_appt_date
    end
    sleep interval
  end

  puts "Done"
  exit -1
end

current_appt_str = ARGV[0]
current_appt_date = Date.parse(current_appt_str)
location_id = ARGV[1]
interval_in_sec = ARGV[2] || 600

run(current_appt_date, location_id, interval_in_sec)

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone)
  phone.gsub!(/\D/, '')
  if phone.length == 10
    phone
  elsif phone.length == 11
    if phone[0] == '1'
      phone[1..phone.length]
    else
      'BAD NUMBER'
    end
  else
    'BAD NUMBER'
  end
end
 
def count_max(array)
  max = array.max_by { |obj| array.count(obj) }
  max_count = array.count(max)
  [max, max_count]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager Initialized!'

# Parsing with CSV, using the CSV library
contents = CSV.open 'event_attendees.csv', headers: true, header_converters: :symbol

template_letter = File.read 'form_letter.erb'
erb_template = ERB.new template_letter

reg_hour_collection = []
reg_day_collection = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  phone_number = clean_phone_number(row[:homephone])

  reg_date = DateTime.strptime(row[:regdate], "%m/%e/%y %k:%M")
  reg_hour_collection << reg_date.hour
  reg_day_collection << reg_date.strftime('%A')

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  # Outputting form letters to a file
  save_thank_you_letter(id, form_letter)
  puts "#{name} : #{phone_number} #{reg_date.hour} #{reg_date.strftime('%A')}"
end
peak_hour = count_max(reg_hour_collection)
peak_day = count_max(reg_day_collection)

puts "Most people(#{peak_hour[1]}) registered at #{peak_hour[0]}00 hours."
puts "Most people(#{peak_day[1]}) registered on #{peak_day[0]}."
require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

  

def clean_phone_number (number)
  number.gsub!("-","")
  number.gsub!(" ","")
  number.gsub!("(","")
  number.gsub!(")","")
  number.gsub!(".","")
  if (number.length < 10) || (number.length > 11) || (number.length == 11 && number[0] != 1)
    "Bad Number"
  elsif number[0] == 1
    number[1..]
  elsif number.length == 10
    number
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hour_count = Hash.new(0)
day_holder = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  dnt = row[:regdate].split(" ")
  frmtter = dnt[0].split("/")
  frmtter[2] = frmtter[2].rjust(4, "20")
  insertion = []
  insertion.push(frmtter[2])
  insertion.push(frmtter[0])
  insertion.push(frmtter[1])
  dnt[0] = insertion.join("/")
  time_holder = Time.parse(dnt[1])
  date_holder = Date.parse(dnt[0]).wday

  case date_holder
  when 0
    day_holder["Sunday"] += 1
  when 1
    day_holder["Monday"] += 1
  when 2
    day_holder["Tuesday"] += 1
  when 3
    day_holder["Wednesday"] += 1
  when 4
    day_holder["Thursday"] += 1
  when 5
    day_holder["Friday"] += 1
  when 6
    day_holder["Saturday"] += 1

  end

  hour_count[time_holder.hour] += 1
  
  #puts clean_phone_number(row[:homephone])

  save_thank_you_letter(id,form_letter)
end

p (hour_count.sort_by {|key, value| value}).reverse.to_h
p ((day_holder.sort_by {|key, value| value}).reverse)[0]

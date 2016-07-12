require 'csv'
require 'sunlight/congress'
require 'erb'
# require 'date'

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zipcode)
  Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id,form_letter)
  Dir.mkdir("output") unless Dir.exists?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename,'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(number)
	number = number.scan(/\d+/).join()
	if number.length == 10
		number
	elsif number.length == 11 and number[0] == "1"
		number.rjust(10, "0")[1..10] 
	else
		number = "0000000000"
	end
end

# def find_peak_hours(hours)
# 	hours_arr = hours.sort_by {|hour, number| number}.reverse()
# 	puts "Peak hours of registration:"
# 	(0..2).each do |i|
# 		puts "Time: #{hours_arr[i][0]}, number of registrants: #{hours_arr[i][1]}"
# 	end
# end

# def find_peak_days(wdays)
# 	days_arr = wdays.sort_by {|day, number| number}.reverse()
# 	puts "Peak days of registration:"
# 	(0..2).each do |i|
# 		puts "Day: #{days_arr[i][0]}, number of registrants: #{days_arr[i][1]}"
# 	end
# end

def find_peak(hash)
	arr = hash.sort_by {|item, value| value}.reverse()
	return (0..2).map{|i| [arr[i][0], arr[i][1]]}
end

puts "EventManager initialized."

contents = CSV.open 'event_attendees.csv', headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

hours = Hash.new(0)
wdays = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letters(id,form_letter)

  number = clean_phone_number(row[:homephone])
  puts "Phone number of #{name}: #{number}"

  reg_date = DateTime.strptime(row[:regdate],'%m/%d/%y %H:%M')
  hours[reg_date.hour] += 1

  week_day = Date.strptime(row[:regdate],'%m/%d/%y %H:%M').wday
  wdays[week_day] += 1
end

puts "\nPeak hours of registration:"
find_peak(hours).each do |hour, n|
	puts "Hour: #{hour}, number of registrations: #{n}" 
end
puts "\nPeak days of registration:"
find_peak(wdays).each do |day, n|
	puts "Day: #{day}, number of registrations: #{n}" 
end
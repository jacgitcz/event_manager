
require "csv"
require "sunlight/congress"
require "erb"

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
	zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zipcode)
	legislators = Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id, form_letter)
	Dir.mkdir("output") unless Dir.exists? "output"

	filename = "output/thanks_#{id}.html"

	File.open(filename, 'w') do |file|
		file.puts form_letter
	end
end

def clean_phone_number(number)
    number.gsub!(/\D/, "") # remove non-digits
	numlen = number.length

	case numlen
	when 0..9
		BAD_PHONE_NUM
	when 10
		number
	when 11
		if number[0] == "1"
			number[1..9]
		else
			BAD_PHONE_NUM
		end
	else
		BAD_PHONE_NUM
	end
end

def clean_timedate(datetime)
	dt_array = datetime.split(" ")
	date = dt_array[0]
	time = dt_array[1]
	date_arr = date.split("/")
	time_arr = time.split(":")
	date_arr.map! {|d| d.rjust(2,"0")}
	time_arr.map! {|t| t.rjust(2,"0")}
	date_arr[2] = "20" + date_arr[2]  # convert year to 4 figures
	date2 = date_arr.join("/")
	time2 = time_arr.join(":")
	return date2 + " " + time2
end

def make_date(date_str)
	date = DateTime.strptime(date_str,"%m/%d/%Y %H:%M")
end

def get_hour(date)	
	reg_hour = date.strftime("%H")
end

def get_day_of_week(date)
	reg_day = date.wday
end

BAD_PHONE_NUM = "0000000000"  # marker for bad phone number
DAY_NAMES = %w[Sun Mon Tue Wed Thu Fri Sat]
puts "EventManager Initialized!"

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

reg_hours = Hash.new(0)
reg_days = Hash.new(0)

contents.each do |row|
	id = row[0]
	name = row[:first_name]

	phone_number = clean_phone_number(row[:homephone])

	reg_date = make_date(clean_timedate(row[:regdate]))

	reg_hours[get_hour(reg_date)] += 1 # build table of hours and registrations
	
	reg_days[get_day_of_week(reg_date)] += 1

	zipcode = clean_zipcode(row[:zipcode])

	legislators = legislators_by_zipcode(zipcode)

	form_letter = erb_template.result(binding)

	save_thank_you_letters(id, form_letter)

end
hours = reg_hours.keys.sort
puts "Peak registration hours\n"
puts "From: \t To: \t Registrations"
hours.each do |hour|
	puts "#{hour}:00 \t #{hour}:59 \t #{reg_hours[hour]}"
end
wdays = reg_days.keys.sort
puts
puts "Peak registration days"
puts "Day \t Registrations"

wdays.each do |weekday|
	puts "#{DAY_NAMES[weekday]} \t #{reg_days[weekday]}"
end
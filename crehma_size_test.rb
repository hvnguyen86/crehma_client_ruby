require 'net/http'
require 'securerandom'
require 'time'
require './params'
require './utils'
require "csv"



number_of_total_test = $number_of_valid_test + $number_of_invalid_test;

$csv_array = Hash.new
path = SecureRandom.hex(10)
uri = URI("http://"+$host+"/rsc/"+path)
#puts uri.to_s
#x_response = $x_response+";abl:"+abl
delta = makeRequest(uri,$x_response,$signature,$replay_attack_protection)
ver_times = ""
times = ""
content_length = 0
j = 0
while j < $steps
	i = 0
	#puts $abl
	path = SecureRandom.hex(10)
	uri = URI("http://"+$host+"/rsc/"+path)
	x_response = $x_response+";abl:"+$abl.to_s
	times_array = Array.new
	while i < number_of_total_test
  
	  results = makeRequest(uri,x_response,$signature,$replay_attack_protection)
	  delta = results[0]
	  content_length = results[1]
	  ver = results[2]
	  times = times + delta.to_s + "\n"
	  ver_times = ver_times + ver.to_s + "\t" + content_length.to_s + "\n"
	  puts "delta: #{delta} content_length: #{content_length} ver: #{ver}"
	  times_array.push(delta)
	  i += 1
	  sleep $pause
	end
	$csv_array[content_length.to_i] = times_array
	j += 1
	$abl = $abl + $stepSize

end



x_response_filename = $x_response.gsub("cc:","").gsub("=","_").gsub("-","_")

$csv = ""
#puts $csv_array
#csv = $csv_array.to_csv
filename = "./size_test_#{x_response_filename}_#{$host}_#{$number_of_valid_test}_sig_#{$signature}"+(Time.now.to_f * 1000).to_i.to_s+".csv"

$csv_array.each do |key, value|
  $csv = $csv + key.to_s + "\t"
  value.each do |v|
    $csv = $csv + v.to_s + "\t"
  end
  $csv = $csv + "\n"
end

# CSV.open(filename, "w", headers: $csv_array.keys) do |csv|
#     csv << $csv_array.values
# end

# CSV.open(filename, "wb") do |csv|
# 	csv << first.keys # adds the attributes name on the first line
# 	self.each do |hash|
# 		hostash.values.each do |value|
# 			csv << value
# 		end
#     end
# end

# CSV.open(filename, "wb") {|csv| $csv_array.to_a.each {|elem| csv << elem} }
File.write("./size_test_#{x_response_filename}_#{$host}_#{$number_of_valid_test}_sig_#{$signature}"+(Time.now.to_f * 1000).to_i.to_s+".txt", $csv)
File.write("./ver_time_size_test_#{x_response_filename}_#{$host}_#{$number_of_valid_test}_sig_#{$signature}"+(Time.now.to_f * 1000).to_i.to_s+".txt", ver_times)
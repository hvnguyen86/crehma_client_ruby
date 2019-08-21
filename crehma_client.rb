require 'net/http'
require 'securerandom'
require 'time'
require './params'
require './utils'




number_of_total_test = $number_of_valid_test + $number_of_invalid_test;

i = 0
path = SecureRandom.hex(10)
uri = URI("http://"+$host+"/rsc/"+path)
puts uri.to_s
delta = makeRequest(uri,$x_response,$signature,$replay_attack_protection)
ver_times = ""
times = ""

while i < number_of_total_test
  puts uri.to_s
  results = makeRequest(uri,$x_response,$signature,$replay_attack_protection)
  #puts results
  content_length = results[1]
  delta = results[0]
  ver = results[2]
  times = times + delta.to_s + "\n"
  ver_times = ver_times + ver.to_s + "\t" + content_length.to_s + "\n"
  puts "delta: #{delta} content_length: #{content_length} ver: #{ver}"
  #puts delta
  #puts content_length
  i += 1
  sleep $pause
end

x_response_filename = $x_response.gsub("cc:","").gsub("=","_").gsub("-","_")

File.write("./#{x_response_filename}_#{$host}_#{$number_of_valid_test}_sig_#{$signature}"+(Time.now.to_f * 1000).to_i.to_s+".txt", times)
File.write("./ver_time_#{x_response_filename}_#{$host}_#{$number_of_valid_test}_sig_#{$signature}"+(Time.now.to_f * 1000).to_i.to_s+".txt", ver_times)

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
delta = makeRequest(uri,$x_response,$signature)

times = ""

while i < number_of_total_test
  
  delta = makeRequest(uri,$x_response,$signature)
  times = times + delta.to_s + "\n"
  puts delta
  i += 1
end

x_response_filename = $x_response.gsub("cc:","").gsub("=","_").gsub("-","_")

File.write("./#{x_response_filename}_#{$host}_#{$number_of_valid_test}_sig_#{$signature}"+(Time.now.to_f * 1000).to_i.to_s+".txt", times)
require 'net/http'
require 'securerandom'
require 'time'
require './params'

def makeRequest(uri,x_response,signature)
	# req = Net::HTTP::Get.new(uri)

	# http = Net::HTTP.new(uri.host, uri.port)

	# req = Net::HTTP::Get.new(uri.request_uri)
	req = Net::HTTP::Get.new(uri)
	req["X-Response"] = x_response
	start = (Time.now.to_f * 1000).to_i
	# res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') {|http|
	# 	http.request(req)
	# }

	res = Net::HTTP.start(uri.hostname, uri.port) {|http|
  		http.request(req)
	}

	# response = http.request(req)
	finish = (Time.now.to_f * 1000).to_i
	delta = finish - start
	return delta
end


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

x_response_filename = $x_response.gsub("cc:","").gsub("=","_")

File.write("./#{x_response_filename}_#{$host}_"+(Time.now.to_f * 1000).to_i.to_s+".txt", times)
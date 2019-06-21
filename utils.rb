require 'time'
require "base64"
require "openssl"
require "json"
$tbsRequestHeaders = Array[
"Host",
"Accept",
"Content-Type",
"Transfer-Encoding",
"Content-Length"
].sort

$tbsResponseHeaders = Array[
"ETag",
"Expires",
"Cache-Control",
"Content-Length",
"Content-Type",
"Last-Modified",
"Transfer-Encoding"
].sort

$verifiedSignatures = Array.new
#puts $tbsResponseHeaders

def makeRequest(uri,x_response,signature)
	
	req = Net::HTTP::Get.new(uri)
	req["X-Response"] = x_response
	req["Accept"] = "application/json"
	start = (Time.now.to_f * 1000).to_i
	if signature
		 req["Signature"] = signRequest(req)
		 req["Create-Signature"] = "true"
		#puts signRequest(req)
	end
	res = Net::HTTP.start(uri.hostname, uri.port) {|http|
  		http.request(req)
	}

	#puts req.each_header.to_h

	if signature
		if !verifyResponse(res,uri.hostname+uri.path,"GET")
			puts "Wrong Signature"
		end
	end
	# puts res.code
	# puts res.body
	# puts res.each_header.to_h
	# response = http.request(req)
	json = JSON.parse(res.body)
	puts json["Id"]
	finish = (Time.now.to_f * 1000).to_i

	delta = finish - start
	results = Array[delta,res["Content-Length"]]
	return results
end

$base64Key = "fJW7ebII2E4RU3fD4BjixIDnV++0mq8LUY5TMx2C/g5nRDDies4AFLZ939sU1uoMH+uey1xUMKVSFCd+VNXg+4yOS1M/DtM+9ObW108iNmlXZQsKgXLkRLrBkZ78y2r8Mml3WXe14ktXjCjhRXTx5lBsTKMEcBTxepe1aQ+0hLNOUDhsUKr31t9fS5/9nAQC7s9sPln54Oic1pnDOIfnBEku/vPl3zQCMtU2eRk9v+AfschSUGOvLV6Ctg0cGuSi/h8oKZuUYXrjoehUo1gBvZLVBpcCxZt1/ySGTInLic3QbfZwlT5sJKrYvfHXjANOEIM7JZMaSnfMdK2R9OJJpw=="
$key = Base64.decode64($base64Key)
$kid = "jREHMAKey";
$sig = "HMAC/SHA256";
$hash = "SHA256";
$signatureHeaderTemplate = "sig=%s,hash=%s,kid=%s,tvp=%s,addHeaders=%s,sv=%s";
$hashOfEmptyBody = "47DEQpj8HBSa-_TImW-5JCeuQeRkm5NMpJWZG3hSuFU"
$sha256 = OpenSSL::Digest::SHA256.new

def signRequest(request)
	tvp = Time.now.iso8601
	tbs = tvp + "\n"
	tbs = tbs +  "GET" + "\n"
	tbs = tbs + request.path + "\n"
	tbs = tbs + "HTTP/1.1" + "\n"

	$tbsRequestHeaders.each do |header|
		if request[header] == nil
			tbs = tbs + "\n"
		else
    		tbs = tbs + request[header] + "\n"
    	end
	end
	tbs = tbs + $hashOfEmptyBody
	sv  = Base64.urlsafe_encode64(OpenSSL::HMAC.digest('sha256', $key, tbs)).gsub("=","")
	signatureHeaderTemplate = "sig=HMAC/SHA256,hash=SHA256,kid=jREHMAKey,tvp=#{tvp},addHeaders=null,sv=#{sv}";
	return signatureHeaderTemplate
end

def verifyResponse(response, cacheKey, method)
	signatureHeader = response["Signature"]
	signatureHeaderParams = signatureHeader.split(",")
	sv_to_check = ""
	tvp = ""
	signatureHeaderParams.each do |param|
		item = param.split("=")
		if item[0] == "tvp"
			tvp = item[1]
		elsif item[0] == "sv"
		 	sv_to_check = item[1]
		end
	end
	
	
	tbs = tvp + "\n"
	tbs = tbs + method + "\n"
	tbs = tbs + cacheKey + "\n"
	tbs = tbs + "HTTP/1.1" + "\n"
	tbs = tbs + response.code + "\n"
	$tbsResponseHeaders.each do |header|
		#puts header
		if response[header] == nil
			tbs = tbs + "\n"
		else
    		tbs = tbs + response[header] + "\n"
    	end
	end

	tbs = tbs + Base64.urlsafe_encode64($sha256.digest(response.body)).gsub("=","")
	# puts "------"
	# puts tbs
	# puts "------"
	sv  = Base64.urlsafe_encode64(OpenSSL::HMAC.digest('sha256', $key, tbs)).gsub("=","")
	if sv_to_check == sv
		if $verifiedSignatures.include?(sv)
			maxAge = 0
			cacheControlHeader = response["Cache-Control"]
			cacheControlHeaderParams = cacheControlHeader.split(",")
			cacheControlHeaderParams.each do |param|
				if param.start_with?("max-age=")
					maxAge = param.split("=")[1]
				end
			end

			if verifySignatureFreshness(maxAge,tvp)
				
				return true
			else
				puts "Duplicate Signature not fresh"
				return false
			end
			
		else
			$verifiedSignatures.push(sv)
		end
		
		return true
	else
		return false
	end
end

def verifySignatureFreshness(maxAge,tvp)

	tvpDate = (Time.parse(tvp).to_f * 1000).to_i

	delta = 0
	now = (Time.now.to_f * 1000).to_i
	signatureExpirationDate = tvpDate + 5000 + Integer(maxAge) * 1000;
	# puts "sig: #{signatureExpirationDate}"
	# puts "no: #{now}"
	if now < signatureExpirationDate
		return true
	else 
		return false
	end
end
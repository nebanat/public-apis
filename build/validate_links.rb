#!/usr/bin/env ruby
require 'httparty'
require 'ruby-progressbar'
require 'uri'
allowed_codes = [200, 302, 403]
args = ARGV
filename = args[0]
contents = File.open(filename, 'rb') { |f| f.read }
raw_links = URI.extract(contents, ['http', 'https'])
# Remove trailing ')' from entry URLs
links = []
raw_links.each do |link|
    if link.end_with?(')')
        links.push(link[0...-1])
    else
        links.push(link)
    end
end
fails = []
# Fail on any duplicate elements
dup = links.select{|element| links.count(element) > 1}
if dup.uniq.length > 0
    dup.uniq.each do |e|
        fails.push("Duplicate link: #{e}")
    end
end
# Remove any duplicates from array
links = links.uniq
count = 0
total = links.length
progressbar = ProgressBar.create(:total => total)
# GET each link and check for valid response code from allowed_codes
links.each do |link|
    begin
        count += 1
        res = HTTParty.get(link, timeout: 10)
        if res.code.nil?
            fails.push("(NIL): #{link}")
            next
        end
        if !allowed_codes.include?(res.code)
            fails.push("(#{res.code}): #{link}")
        end
    rescue Net::ReadTimeout
        fails.push("(TMO): #{link}")
    rescue OpenSSL::SSL::SSLError
        fails.push("(SSL): #{link}")
    rescue SocketError
        fails.push("(SOK): #{link}")
    rescue
        fails.push("(ERR): #{link}")
    end
    progressbar.increment
end
puts "#{count}/#{total} links checked"
if fails.length <= 0
    puts "all links valid"
    exit(0)
else
    puts "-- RESULTS --"
    fails.each do |e|
        puts e
    end
    exit(1)
end

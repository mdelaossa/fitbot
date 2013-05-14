#!/usr/bin/env ruby
#
#  Class to work with http://pastebin.com
#
require 'net/http'
require 'uri'
require 'rexml/document'

class Pastebin
    include REXML

    DEVKEY = "488377154360aa0d54095b290e5d5335"

    # The only option required is 'paste_code', which holds your string.
    #
    def initialize()
        @options = {}
        @options["api_dev_key"] = DEVKEY
        @options["api_paste_private"] = 1
    end

    # This POSTs the paste and returns the link
    #
    #   pbin.paste    #=> "http://pastebin.com/xxxxxxx"
    #
    def paste(text)
        @options["api_paste_code"] = text
        @options["api_option"] = "paste"
        Net::HTTP.post_form(URI.parse('http://pastebin.com/api/api_post.php'),
                            @options).body
    end

    # This method takes a link from a previous paste and returns the raw
    # text.
    #
    #   pbin.get_raw("http://pastebin.com/xxxxxxx")    #=> "some text"
    #
    def get_raw(link)
        Net::HTTP.get_response(URI.parse("http://pastebin.com/raw.php?i=#{link[/[\w\d]+$/]}")).body
    end
end
#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'date'
require 'open-uri'
require 'date'
require 'uri'

# require 'colorize'
# require 'pry'
# require 'csv'
# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'

@BASE = 'http://www.assemblee-nationale.cg'
@GENDER = {
  'masculin' => 'male',
  'feminin' => 'female',
}

class String
  def trim
    self.gsub(/[[:space:]]/,' ').strip
  end
end

def noko(url)
  url.prepend @BASE unless url.start_with? 'http:'
  Nokogiri::HTML(open(url).read) 
end

added = 0

(1..18).each do |page_number|
  url = @BASE + "/deputes.php?page=#{page_number}"
  warn "Getting #{url}"
  page = noko(url)
  page.css('td#survol_lois a/@href').map(&:text).each do |link|
    member_url = URI.join(url, link).to_s 
    box = noko(member_url).css('div#fiche_deputes table').first
    tds = box.css('td')
    title = tds[3].text.strip.split("\n").map(&:trim)
    data = { 
      id: member_url[/id_deputes=(\d+)/, 1],
      name: title.first.gsub(/\s+/,' ').gsub('Honorable ',''),
      district: title.last.gsub('Circonscription de ',''),
      picture: tds[0].css('img/@src').text,
      departement: tds[8].text.strip,
      gender: @GENDER[tds[10].text.strip],
      party: tds[12].text.strip,
      term: '13',
      source: member_url,
    }
    data[:party] = "Independent" if data[:party].empty? || data[:party] == 'INDEPENDANT'
    data[:picture] = URI.join(member_url, URI.escape(data[:picture])).to_s unless data[:picture].nil? or data[:picture].empty?
    # puts data.values.to_csv
    added += 1
    ScraperWiki.save_sqlite([:id, :term], data)
  end
end

puts "Added #{added} members"

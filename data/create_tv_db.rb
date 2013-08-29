#!/usr/bin/env ruby
# encoding: utf-8
#
# creates tv_cards.yml - a database with the TV cards
#
# YAML file structure:
# {
#   "name" => <vendor_name>
#   "cards" => [
#       {
#         "name" : <card name>,
#         "module" : [<driver>],
#         "parameters" => {
#           <param> => <value>
#         }
#       },
#       ...
#   ]
# }
#

require 'yaml'

if ARGV.empty?
  puts "Please, specify the source files as parameters!"
  exit 1
end

# List of the known vendors
KNOWN_VENDORS = /^(
  ATI
| Askey
| Asus
| AVerMedia
| AverTV
| Beholder
| BESTBUY
| Compro
| DViCO
| FlyVideo
| GrandTec
| Hauppauge
| Intel
| KWorld
| Leadtek
| LifeView
| MATRIX-Vision
| MIRO
| MSI
| Osprey
| Phoebe
| Pinnacle
| Prolink
| STB
| Terratec
| Zoltrix
)/x


# Parse plain text files like "CARDLIST.bttv" containing card names
def read_database(files)
  cards = []

  files.each do |file|
    # driver name is in the file extension
    driver = File.extname file
    # remove the dot at the beginning
    driver[0] = ""

    File.readlines(file).each do |line|
      # ignore not matching lines
      next unless line.match /^(.*)->(.*)$/

      param = $1.strip
      card_name = $2.strip

      # Clean the name
      card_name = $1.strip if card_name.match /^(.*)\s+\[.*:.*\]/
      card_name = $1.strip if card_name.match /^(.*)\s+\((em|au|tm).*\)$/
      card_name = "Unknown card (driver #{driver})" if card_name.match "UNKNOWN/GENERIC"

      cards << {
        "name" => card_name,
        "module" => [driver],
        "parameters" => {driver => {"card" => param}},
      }
    end
  end

  cards
end

def group_by_vendors(cards)
  ret = []
  cards_by_vendors = {}

  cards.each do |card|
    vendor = card["name"].match(KNOWN_VENDORS) ? $1 : "Other vendors"

    vendor_cards = cards_by_vendors[vendor] || []
    cards_by_vendors[vendor] = vendor_cards << card
  end

  # Sort cards
  cards_by_vendors.each do |vendor, cards|
    # put the "unknown" cards at the beginning
    unknown = cards.select{|c| c["name"].start_with?("Unknown") }
    cards.reject!{|c| c["name"].start_with?("Unknown") }
    cards.sort! {|a,b| a["name"] <=> b["name"]}

    ret << {"name" => vendor, "cards" => unknown + cards}
  end

  ret
end

cards = read_database(ARGV);
db = group_by_vendors(cards)

puts db.to_yaml

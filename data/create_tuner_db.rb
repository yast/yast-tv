#!/usr/bin/env ruby
# encoding: utf-8
#
# creates tv_tuners.yml - a database with the TV tuners
#
# parameter - the CARDLIST.tuner source file
#
# YAML file structure:
# {
#   <driver_name> => [
#       {
#         "name" : <tuner_name>,
#         "parameters" => {
#           <param> => <value>
#         }
#       },
#       ...
#   ]
# }
#

require 'yaml'

# Parameters
bttv_cardlist = ARGV[0];

if !bttv_cardlist
  puts "Please, specify the source file as a parameter!";
  exit 1
end

# Parse the tuner DB file
def parse_tuner_file(input_file)
  tuner_array = []

  # add the "No Tuner" item at the beginning
  no_tuner = {}

  File.open(input_file, "r").each_line do |line|
    # create the line
    if line.match /^\s*([^=]*)=(\S*)\s*-\s*(.*)$/
	    # Clean the name
	    card_name = $3;

      if card_name == "NoTuner"
        no_tuner = {"name" => "No Tuner", "parameters" => {$1 => $2}}
      else
        tuner_array << {"name" => card_name, "parameters" => {$1 => $2}}
      end

    end
  end

  tuner_array.sort! {|a, b| a["name"].upcase <=> b["name"].upcase}

  tuner_array.unshift(no_tuner)
end

tuners = parse_tuner_file(bttv_cardlist)

# this results in using references in the YAML result,
# thats saves space in YAML file and also saves memory at runtime
db = { "bttv" => tuners, "cx88xx" => tuners}

puts db.to_yaml

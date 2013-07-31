# encoding: utf-8

# File:	modules/ModulesComments.ycp
# Package:	TV cards configuration
# Summary:	Library for handling special comments in /etc/modules.conf
# Authors:	Jan Holesovsky <kendy@suse.cz>
#
# $Id$
#
# Functions for handling special comments in /etc/modules.conf
require "yast"

module Yast
  class ModulesCommentsClass < Module
    # Create comment for modules.conf from the unique key and the name
    # of the card. It will be parsed when reading.
    # This comment should be placed before the alias differentiating
    # the card (char-major-81-x for TV cards, ethx for ethernet, ...)
    # @param [String] name Name of the card
    # @param [String] unique_key Unique key
    # @return [String] The comment.
    # @example
    #    ModulesComments::StoreToComment ("Ultra brutal TV card", "xyza.aiLKJkjsdlj")
    # -> "# xyza.aiLKJkjsdlj:Ultra brutal TV card\n"
    def StoreToComment(name, unique_key)
      name = "Unknown card" if name == nil
      unique_key = "uniq.key" if unique_key == nil

      Builtins.sformat("# %1:%2\n", unique_key, name)
    end

    # Extacts the unique key and the name of the card from comment in the
    # modules.conf placed before the alias differentiatin the card.
    # @param [String] comment The comment
    # @return [Hash] Returns map: $[ "unique_key" : string, "name" : string ]
    # @example
    #    ModulesComments::ExtractFromComment ("# xyza.aiLKJkjsdlj:Ultra brutal TV card\n")
    # -> $[ "name" : "Ultra brutal TV card", "unique_key" : "xyza.aiLKJkjsdlj" ]
    def ExtractFromComment(comment)
      comment = "" if comment == nil

      result = { "name" => "", "unique_key" => "" }

      # split to lines
      comment_lines = Builtins.splitstring(comment, "\n")

      # find last line with a ":"
      line_with_uk = ""
      colon_pos_uk = nil
      Builtins.foreach(
        Convert.convert(comment_lines, :from => "list", :to => "list <string>")
      ) do |line|
        c_pos = Builtins.findfirstof(line, ":")
        if c_pos != nil
          line_with_uk = line
          colon_pos_uk = c_pos
        end
      end

      # did we find it?
      if colon_pos_uk != nil
        # extract name
        name = Builtins.substring(
          line_with_uk,
          Ops.add(colon_pos_uk, 1),
          Ops.subtract(
            Ops.subtract(Builtins.size(line_with_uk), colon_pos_uk),
            1
          )
        )
        # extract unique key
        start_uk = Builtins.findfirstnotof(line_with_uk, "# \t")
        uk = Builtins.substring(
          line_with_uk,
          start_uk,
          Ops.subtract(colon_pos_uk, start_uk)
        )

        result = { "name" => name, "unique_key" => uk }
      end

      deep_copy(result)
    end

    publish :function => :StoreToComment, :type => "string (string, string)"
    publish :function => :ExtractFromComment, :type => "map (string)"
  end

  ModulesComments = ModulesCommentsClass.new
end

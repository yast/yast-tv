# encoding: utf-8

# File:	clients/irc.ycp
# Package:	TV cards configuration
# Summary:	Client for stand-alone IRC configuration
# Authors:	Jiri Suchomel <jsuchome@novell.com>
#
# $Id$
#
# Main file for LIRC configuration.
module Yast
  class IrcClient < Client
    def main
      Yast.import "UI"
      #**
      # <h3>Configuration of IRC</h3>

      textdomain "tv"

      Yast.import "Tv"
      Yast.include self, "tv/irc_ui.rb"

      Wizard.CreateDialog
      Wizard.SetDesktopIcon("tv") #FIXME need irc icon
      Wizard.SetDialogTitle(_("IRC")) #FIXME need irc icon

      @callback = lambda { UI.PollInput == :abort }
      Tv.Read(@callback)
      Tv.ReadIRC

      @ret = IRCDialog(true)

      Tv.WriteIRC if @ret == :next

      deep_copy(@ret) 

      # EOF
    end
  end
end

Yast::IrcClient.new.main

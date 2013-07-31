# encoding: utf-8

# File:	clients/tv_auto.ycp
# Package:	TV cards configuration
# Summary:	Client for autoinstallation
# Authors:	Jan Holesovsky <kendy@suse.cz>
#
# $Id$
#
# This is a client for autoinstallation. It takes its arguments,
# goes through the configuration and returns the settings.
# Does not do any changes to the configuration.

# @param first a map of tv settings
# @example
#    map mm = $[ "cards" : [] ];
#    map ret = WFM::CallModule ("tv_auto", [ mm ]);
module Yast
  class TvAutoClient < Client
    def main
      Yast.import "UI"

      textdomain "tv"

      Yast.import "Label"
      Yast.import "Tv"
      Yast.import "Wizard"

      Yast.include self, "tv/ui.rb"

      @args = WFM.Args
      if Ops.less_or_equal(Builtins.size(@args), 0)
        Builtins.y2error("Did not get the settings, probably some mistake...")
        return nil
      end
      if !Ops.is_map?(WFM.Args(0))
        Builtins.y2error("Bad argument for tv_auto: %1", WFM.Args(0))
        return nil
      end

      # The settings are in the first argument
      @settings = Ops.get_map(@args, 0, {})
      Builtins.y2milestone("Imported: (%1)", @settings)

      # A callback function for abort
      @callback = lambda { UI.PollInput == :abort }

      @caption = _("Initializing TV and Radio Card Configuration")
      @contents = Label(_("Initializing..."))

      # Construct the dialogs
      Wizard.CreateDialog
      Wizard.SetDesktopTitleAndIcon("tv")
      Wizard.SetContentsButtons(
        @caption,
        @contents,
        "",
        Label.BackButton,
        Label.NextButton
      )
      Wizard.RestoreHelp(ReadDialogHelp())

      # Read the settings from the current system
      return nil if !Tv.Read(@callback)
      # and patch them with the imported data
      Tv.Import(@settings)

      if MainSequence() == :next
        @settings = Tv.Export
      else
        @settings = {}
      end
      deep_copy(@settings) 

      # EOF
    end
  end
end

Yast::TvAutoClient.new.main

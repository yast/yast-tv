# encoding: utf-8

# File:	clients/tv_proposal.ycp
# Package:	TV cards configuration
# Summary:	Proposal function dispatcher.
# Authors:	Jan Holesovsky <kendy@suse.cz>
#
# $Id$
#
# Proposal function dispatcher for tv configuration.
module Yast
  class TvProposalClient < Client
    def main
      Yast.import "UI"

      textdomain "tv"

      Yast.import "Tv"
      Yast.import "Progress"
      Yast.import "GetInstArgs"

      @func = Convert.to_string(WFM.Args(0))
      @param = Convert.to_map(WFM.Args(1))
      @ret = {}

      # Make proposal for installation/configuration...
      if @func == "MakeProposal"
        @force_reset = Ops.get_boolean(@param, "force_reset", false)
        @proposal = ""
        @warning = nil
        @warning_level = nil

        # Let's generate the proposal
        if @force_reset || !Tv.proposal_valid
          Tv.proposal_valid = true

          # Do not show any progress during Read ()
          @progress = Progress.set(false)

          if !GetInstArgs.automatic_configuration
            # Progress message
            UI.OpenDialog(VBox(Label(_("Detecting TV cards..."))))
          end
          Tv.ReadCardsDatabase
          Tv.ReadSettings
          Tv.Detect
          Tv.ReadIRC
          UI.CloseDialog if !GetInstArgs.automatic_configuration

          Progress.set(@progress)

          Tv.Propose
        end

        @proposal = Tv.Summary

        # Fill return map
        @ret =
          #"warning"               : warning,
          #"warning_level"         : warning_level
          { "preformatted_proposal" => @proposal }
      # Run an interactive workflow
      elsif @func == "AskUser"
        @stored = Tv.Export

        # Do not show any progress during Read ()
        @progress = Progress.set(false)
        Tv.ReadCardsDatabase
        Tv.ReadTunersDatabase
        Progress.set(@progress)

        @seq = WFM.CallFunction("tv", [path(".noio")])

        Tv.Import(@stored) if @seq != :next

        # Fill return map
        @ret = { "workflow_sequence" => @seq }
      # Return human readable titles for the proposal
      elsif @func == "Description"
        # Fill return map
        @ret = {
          "rich_text_title" =>
            # Richtext title
            _("TV Cards"),
          "menu_title" =>
            # Richtext title
            _("&TV Cards"),
          "id"              => "tv_conf"
        }
      # Write the settings
      elsif @func == "Write"
        @has_next = Ops.get_boolean(@param, "has_next", false)
        @success = true

        if Tv.IsDirty
          # do not confirm package installation in the automatic mode
          Tv.SetConfirmPackages(!GetInstArgs.automatic_configuration)

          @abort = lambda { false }
          @success = Tv.Write(@abort)
        end

        # Fill return map
        @ret = { "success" => @success }
      end

      deep_copy(@ret) 

      # EOF
    end
  end
end

Yast::TvProposalClient.new.main

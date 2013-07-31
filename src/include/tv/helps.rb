# encoding: utf-8

# File:	include/tv/helps.ycp
# Package:	TV cards configuration
# Summary:	Functions returning help texts.
# Authors:	Jan Holesovsky <kendy@suse.cz>
#
# $Id$
#
# All the help texts for the dialogs.
module Yast
  module TvHelpsInclude
    def initialize_tv_helps(include_target)
      textdomain "tv"
    end

    # Help for the ReadDialog () dialog.
    # @return The help text.
    def ReadDialogHelp
      # For translators: tv read dialog help, part 1 of 2
      _(
        "<P><B><BIG>Initializing TV and Radio Card Configuration</BIG></B><BR>\n" +
          "Please wait...\n" +
          "<BR></P>\n"
      ) +
        # For translators: tv read dialog help, part 2 of 2
        _(
          "<P><B><BIG>Aborting the Initialization</BIG></B><BR>\n" +
            "Safely abort the configuration utility by pressing <B>Abort</B>\n" +
            "now.\n" +
            "</P>\n"
        )
    end

    # Help for the WriteDialog () dialog.
    # @return The help text.
    def WriteDialogHelp
      # For translators: tv write dialog help
      _(
        "<P><B><BIG>Saving TV and Radio Configuration</BIG></B><BR>\n" +
          "Please wait...\n" +
          "<BR></P>\n"
      )
    end

    # Help texts for DetectedDialog()
    # @return The help text.
    def DetectedDialogHelp
      # Help: Detected cards, part 1 of 3
      _(
        "<P><B><BIG>TV and Radio Card Configuration</BIG></B><BR>\n" +
          "Here, configure your TV and radio cards.\n" +
          "<BR></P>\n"
      ) +
        # Help: Detected cards, part 2 of 3
        _(
          "<P><B><BIG>Adding a TV or Radio Card</BIG></B><BR>\n" +
            "Select the card from the list of the unconfigured cards. If your card was\n" +
            "not detected, press <B>Add</B> and configure the card manually.\n" +
            "</P>\n"
        ) +
        # Help: Overview of the installed cards, part 3 of 3
        _(
          "<P><B><BIG>Editing or Deleting</BIG></B><BR>\n" +
            "To change or remove the configuration of a card, select the card.\n" +
            "Then press <B>Edit</B> or <B>Delete</B>.\n" +
            "</P>\n"
        )
    end

    # Help texts for ManualDialog()
    # @return The help text.
    def ManualDialogHelp
      # Help: Manual addition of a card, part 1/3
      _(
        "<P><B><BIG>Manual TV Card Selection</BIG></B><BR>\n" +
          "Select the card type from <b>Vendor</b> and <b>Card</b>.\n" +
          "<BR></P>"
      ) +
        # Help: Manual addition of a card, part 2/3
        _(
          "<P>\n" +
            "If you need to specify the tuner type to get a working\n" +
            "configuration, select your card then press <B>Select Tuner</B>. In the dialog\n" +
            "that opens, select the tuner type.\n" +
            "</P>"
        ) +
        # Help: Manual addition of a card, part 3/3
        _(
          "<P>\n" +
            "In <B>Expert Settings</B>, configure the \n" +
            "kernel module and parameters to use. \n" +
            "This is required for configuring a radio card.\n" +
            "</P>\n"
        )
    end

    # Help texts for ManualDetailsDialog()
    # @parameter allow_changeoftype if true, additional helptext about radio
    # cards is added
    # @return The help text.
    def ManualDetailsDialogHelp(allow_changeoftype)
      helptext =
        # Help: Manual addition of a card: Details, part 1/4
        _(
          "<P><B><BIG>Manual Selection: Details</BIG></B><BR>\n" +
            "Here, you can control all the parameters of the driver of your TV or radio card. This is for experts.\n" +
            "<BR></P>\n"
        ) +
          # Help: Manual addition of a card: Details, part 2/4
          _(
            "In <B>Kernel Module</B>, select the driver to use for the card. The available \n" +
              "parameters for the selected module are listed in <b>Module Parameters</p>.\n" +
              "</P>\n"
          ) +
          # Help: Manual addition of a card: Details, part 3/4
          _(
            "<P>To modify a parameter, select the parameter to change from the list, \n" +
              "write the value in <b>Parameter</b>,  \n" +
              "then press <b>Set</b>. To restore the default setting for the parameter, \n" +
              "press <B>Reset</B>.\n" +
              "</P>"
          )
      if allow_changeoftype
        helptext = Ops.add(
          helptext,
          # Help: Manual addition of a card: Details, part 4/4
          _(
            "<P><B><BIG>Radio Card Configuration</BIG></B><BR>\n" +
              "To select the module for your radio card, check <B>Radio Card Modules</B>.\n" +
              "</P>\n"
          )
        )
      end
      helptext
    end

    # Help texts for AudioDialog()
    # @return The help text.
    def AudioDialogHelp
      # Help: Setup the audio of the card, part 1/3
      _(
        "<P><B><BIG>Audio for TV or Radio Card</BIG></B><BR>\n" +
          "If your TV or radio card has an audio output and it is connected to your sound\n" +
          "card, the sound card's input must be enabled. This can be done here.\n" +
          "<BR></P>\n"
      ) +
        # Help: Setup the audio of the card, part 2/3
        _(
          "<P>If your card is not connected to the sound card, select \n" +
            "<b>Not Connected</b>. If a connection is present, select <b>Connected To</b>. \n" +
            "Select the sound card to which the TV or radio card is connected from the list. \n" +
            "</P>"
        ) +
        # Help: Setup the audio of the card, part 3/3
        _(
          "<P>If the sound card has not been configured yet, press \n" +
            "<b>Configure Sound Cards</b> to start the sound configuration module.\n" +
            "</P>"
        )
    end

    # Help text for ChannelsDialog()
    # @return The help text.
    def ChannelsDialogHelp
      # helptext for TV Stations Dialog 1/3
      _(
        "<p><b><big>TV Station Configuration</big></b>\nHere, see the list of TV stations defined for your system.</p>"
      ) +
        # helptext for TV Stations Dialog 2/3
        _(
          "<p>Edit the entries in the table directly using <b>Add</b>,\n" +
            "<b>Edit</b>, and <b>Delete</b>. Alternatively, use\n" +
            "<b>Scan the Channels</b> to run the scan, which could find the available\n" +
            "TV stations for the given <b>TV Standard</b> and <b>Frequency Table</b>.</b>\n"
        ) +
        # helptext for TV Stations Dialog 3/3
        _(
          "<p>The list of stations shown in this table is saved to the <tt>/etc/X11/xawtvrc</tt> file.</p>"
        )
    end

    # Help text for IRCDialog()
    # @return The help text.
    def IRCDialogHelp
      # IRC helptext 1/3
      _(
        "<p><b><big>Infrared Control Configuration</big></b><br>\nIn this dialog, configure the infrared control of your TV card. To skip this configuration, select <b>Do Not Use IRC</b>.</p>"
      ) +
        # IRC helptext 2/3
        _(
          "<p>If you know which kernel module to use with your TV card, select one from the list. When <b>Show Module Description</b> is checked, also see the description of the module.</p>"
        ) +
        # IRC helptext 3/3
        _("<p>Press <b>Test</b> to test your IR control.</p>")
    end
  end
end

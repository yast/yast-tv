# encoding: utf-8

# File:	modules/Tv.ycp
# Package:	TV cards configuration
# Summary:	Data for configuration of tv, input and output functions.
# Authors:	Jan Holesovsky <kendy@suse.cz>
#
# $Id$
#
# Representation of the configuration of TV cards.
# Input and output routines.
require "yast"

module Yast
  class TvClass < Module
    def main
      Yast.import "UI"

      Yast.import "Directory"
      Yast.import "Progress"
      Yast.import "Report"
      Yast.import "Summary"
      Yast.import "ModulesComments"
      Yast.import "Mode"
      Yast.import "Confirm"
      Yast.import "Service"
      Yast.import "Label"
      Yast.import "Message"
      Yast.import "Package"
      Yast.import "Sound"
      Yast.import "WizardHW"
      Yast.import "HWConfig"
      Yast.import "String"
      Yast.import "FileUtils"

      textdomain "tv"

      # List of all the configured cards.
      # It is read in ReadDialog()
      # @example
      #   [ $[ "name"          : string
      #        "module"        : string,
      #        "parameters"    : $[ string : string ],
      #        "unique_key"    : string,
      #        "sound_card_no" : integer
      #     ],
      #     ...
      #   ]
      @cards = []

      # List of cards which user chooses to delete.
      @cards_to_del = []

      # If the list of the cards changes, this is set to true and Write()
      # must be called.
      @cards_dirty = false

      # The card which is currently being configured.
      # It will become an entry in the "cards" list.
      @current_card = {}

      # The number of card which is currently being configured.
      # It has its meaning only when editing the entry.
      @current_card_no = 0

      # List of all the detected cards.
      # It is initialized in ReadDialog()
      # @example
      #   [ $[ "name"          : string,
      #        "module"        : string,
      #        "unique_key"    : string,
      #     ],
      #     ...
      #   ]
      @detected_cards = nil

      # Database of the TV cards for the manual configuration.
      # It is a list of maps with vendors, and each of the vendor
      # contains a list of cards with the kernel module and
      # its parameters. It is read in ReadDialog()
      # @example
      #   [ $[ "name"  : "ATI",
      #        "cards" :
      #            [ $[ "name"       : "ATI TV-Wonder VE",
      #                 "module"     : "bttv",
      #                 "parameters" : $[ "card" : "64" ]
      #              ],
      #              ...
      #            ],
      #     ],
      #     ...
      #   ]
      @cards_database = nil
      @dvb_cards_database = nil
      @firmware_database = nil

      # Database of the tuners for the manual configuration.
      # It is a map, where the name of the kernel module is the key
      # and a list of maps with name and the module parameters is the value.
      # It is read in ReadDialog()
      # @example
      #   $[ "kernel_module1" :
      #          [ $[ "name"       : "Alps HSBH1",
      #               "parameters" : $[ "tuner" : "9" ]
      #            ],
      #            ...
      #          ],
      #      ...
      #   ]
      @tuners_database = nil

      # Tuner database organized in map of the form $[ tuner_id : tuner_map]
      # @example
      #   $[ "bttv" :
      #       $[ "9": $[ "name" : "Alps HSBH1",
      #                  "parameters" : $[ "tuner" : "9" ]]
      #       ]
      #   ]
      @tuners_by_id = {}

      # Map of available TV kernel modules and their parameters.
      @kernel_modules = nil
      @radio_modules = nil
      @dvb_modules = nil
      @dvb_core_drivers = nil

      # Becomes true, when the module is initialized for proposal.
      @proposal_valid = false

      # If YaST should check the presence of TV/radio application
      @not_ask = false

      # TV application
      @tv_app = "motv"

      # yast temporary directory
      # /tmp is replaced by .target.tmpdir value in Read()
      @tmpdir = "/tmp"

      # This is true, if tv data were read from /etc/modprobe.conf
      # On write, they shoud be removed and written only to /etc/modprobe.d/50-tv.conf
      @used_modprobe_conf = false

      # Were TV stations modified?
      @stations_modified = false

      # Configuration of TV stations (contents of /etc/X11/xawtvrc file)
      @channels_config = {}

      #---------------------------------------- IRC related variables

      # kerenel module used for lirc
      @irc_module = ""

      # configuration file for IR control
      @irc_config = ""

      # Is IRC used?
      @use_irc = false

      # Is IRC modified?
      @irc_modified = false

      # Kernel modules for LIRC
      @irc_modules_list = ["ir-kbd-gpio", "ir-kbd-i2c"]

      # Map of lirc modules, together with their description (from modinfo)
      @irc_modules = {}

      # Paths to config files of various remote controls
      @remotes = []

      # TV cards using irc_kbd_gpio module
      # (matching card numbers from tv_cards.ycp)
      @cards_with_ir_kbd_gpio = {}

      # id's of TV cards, using irc_kbd_gpio module
      # gathered from lirc_gpio.c and bttv-cards.c
      @card_ids_ir_kbd_gpio = [
        #BTTV_PXELVWPLTVPAK
        #BTTV_PXELVWPLTVPRO
        #BTTV_PV_BT878P_9B
        #BTTV_AVERMEDIA
        #BTTV_AVPHONE98
        70753,
        201825,
        #BTTV_AVERMEDIA98
        136289,
        267361,
        #BTTV_CHRONOS_VS2
        407902289,
        #BTTV_MIRO
        #BTTV_DYNALINK
        #BTTV_MAGICTVIEW061
        805442639,
        805639247,
        1342182479,
        805311743,
        #BTTV_MAGICTVIEW063
        805311567,
        #BTTV_PHOEBE_TVMAS
        805442815,
        #BTTV_BESTBUY_EASYTV
        #BTTV_BESTBUY_EASYTV2
        #BTTV_FLYVIDEO
        #BTTV_FLYVIDEO_98
        #BTTV_FLYVIDEO_98FM
        #BTTV_WINFAST2000
        1711673469,
        1711739005,
        561866246,
        #BTTV_WINVIEW_601
        #BTTV_KWORLD
        #BTTV_TYPHOON_TVIEW
        408033362,
        #BTTV_GVBCTV5PCI
        1081086204,
        # SAA7134_BOARD_FLYVIDEO3000
        20468072,
        20467266,
        # SAA7134_BOARD_FLYVIDEO2000
        20468072,
        # SAA7134_BOARD_CINERGY400
        2684754068,
        # SAA7134_BOARD_CINERGY600
        # SAA7134_BOARD_ECS_TVP3XP
        1286869017,
        # SAA7134_BOARD_ECS_TVP3XP_4CB5
        1286934553
      ]

      @firmware_prefix = "/lib/firmware/"

      @fw_source_cache = {}

      # cache for the blacklist
      # modalias blacklist
      @blacklisted_aliases = nil
      # driver blacklist
      @blacklisted_modules = nil

      # confirm installation of extra packages
      @confirm_packages = true

      @lirc_installed = false

      # ------------------- included files:

      Yast.include self, "tv/misc.rb"
      Yast.include self, "sound/write_routines.rb"
    end

    # ------------------- function definitions:

    # Set confirmation flag - when set to false the extra recommended packages are installed automatically
    # @param [Boolean] ask new confirmation flag
    def SetConfirmPackages(ask)
      Builtins.y2milestone("Confirm additional package installation: %1", ask)
      @confirm_packages = ask

      nil
    end

    # Get the current value of the confirmation flag
    # @return [Boolean] true if confirmation is enabled
    def ConfirmPackages
      @confirm_packages
    end

    # Dialog which asks for installing proposed application
    # @param [Array<String>] apps list of applications to install
    # @param [String] text text to show in dialog
    def InstallApplication(apps, text)
      apps = deep_copy(apps)
      ret = :ok

      if ConfirmPackages()
        UI.OpenDialog(
          Opt(:decorated),
          VBox(
            HSpacing(50),
            HBox(VSpacing(6.5), RichText(Id(:rt), text)),
            CheckBox(
              Id(:ch),
              Opt(:notify),
              # checkbox label
              _("Do Not Show This Message &Again")
            ),
            HBox(
              PushButton(Id(:ok), Opt(:key_F10), Label.YesButton),
              PushButton(Id(:cancel), Opt(:key_F9), Label.NoButton)
            )
          )
        )
        begin
          ret = UI.UserInput
          ret = nil if ret == :ch
        end while ret == nil

        @not_ask = Convert.to_boolean(UI.QueryWidget(Id(:ch), :Value))
        UI.CloseDialog
      end

      if ret == :ok
        if ConfirmPackages()
          # display a confirmation dialog
          Package.InstallAll(apps)
        else
          # do not ask the user, install the packages immediately
          Package.DoInstall(apps)
        end
      end

      nil
    end

    #///////////////////////////////////////////////////////////////
    # Some IO functions
    #///////////////////////////////////////////////////////////////

    # Read the state of "not_ask" variable
    # (if the TV/radio application presence should be checked again next time)
    # @return not_ask value
    def ReadUserSettings
      file = Ops.add(Directory.vardir, "/tv.ycp")
      if SCR.Read(path(".target.size"), file) == -1
        SCR.Execute(
          path(".target.bash"),
          Builtins.sformat("/bin/touch %1", file)
        )
        SCR.Write(path(".target.ycp"), file, {})
      else
        state = SCR.Read(path(".target.ycp"), file)
        if Ops.is_map?(state) &&
            Ops.get_boolean(
              Convert.to_map(state),
              "dont_ask_for_application",
              false
            )
          return true
        end
      end
      false
    end


    # Read the database of the TV cards.
    # @return [Boolean] Was the read successful?
    def ReadCardsDatabase
      if @cards_database == nil
        @cards_database = Convert.to_list(
          Builtins.eval(SCR.Read(path(".target.yast2"), "tv_cards.ycp"))
        )
        if @cards_database == nil
          # Error message popup:
          Report.Error(_("Unable to read the TV card database."))
          @cards_database = []
          return false
        end
      end

      if @firmware_database == nil
        @firmware_database = Convert.to_map(
          Builtins.eval(SCR.Read(path(".target.yast2"), "tv_dvbfirmware.ycp"))
        )
        if @firmware_database == nil
          # Error message popup:
          Report.Error(_("Unable to read the TV card database."))
          @firmware_database = {}
          return false
        end
      end

      if @dvb_cards_database == nil
        @dvb_cards_database = Convert.to_list(
          Builtins.eval(SCR.Read(path(".target.yast2"), "tv_dvbcards.ycp"))
        )

        if @dvb_cards_database == nil
          # Error message popup:
          Report.Error(_("Unable to read the TV card database."))
          @dvb_cards_database = []
          return false
        end

        Builtins.y2debug("DVB db: %1", @dvb_cards_database)

        # add DVB flag to each card
        Builtins.foreach(
          Convert.convert(
            @dvb_cards_database,
            :from => "list",
            :to   => "list <map>"
          )
        ) do |vendor|
          cards = Ops.get_list(vendor, "cards", [])
          dvbvendor = Ops.get_string(vendor, "name", "")
          cards = Builtins.maplist(cards) do |card|
            Ops.set(card, "dvb", true)
            deep_copy(card)
          end
          # merge digital cards to analog
          found = false
          # search vendor in analog card database
          @cards_database = Builtins.maplist(
            Convert.convert(
              @cards_database,
              :from => "list",
              :to   => "list <map>"
            )
          ) do |_Avendor|
            _Acards = Ops.get_list(_Avendor, "cards", [])
            vendorname = Ops.get_string(_Avendor, "name", "")
            if vendorname == dvbvendor
              Builtins.y2debug("found vendor in analog DB: %1", vendorname)

              _Acards = Convert.convert(
                Builtins.merge(_Acards, cards),
                :from => "list",
                :to   => "list <map>"
              )
              Ops.set(_Avendor, "cards", _Acards)
              found = true
            end
            deep_copy(_Avendor)
          end
          if !found
            newvendor = { "name" => dvbvendor, "cards" => cards }
            # add vendor and card
            @cards_database = Builtins.add(@cards_database, newvendor)
            Builtins.y2debug("new vendor: %1", dvbvendor)
          end
        end 


        Builtins.y2debug("DVB db: %1", @dvb_cards_database)
      end

      # translate them
      @cards_database = Builtins.eval(@cards_database)

      true
    end

    # Read the database of the tuners.
    # @return [Boolean] Was the read successful?
    def ReadTunersDatabase
      if @tuners_database == nil
        @tuners_database = Convert.to_map(
          Builtins.eval(SCR.Read(path(".target.yast2"), "tv_tuners.ycp"))
        )

        Builtins.foreach(
          Convert.convert(
            @tuners_database,
            :from => "map",
            :to   => "map <string, list <map <string, any>>>"
          )
        ) do |modul, tuners|
          @tuners_by_id = Builtins.add(
            @tuners_by_id,
            modul,
            {
              "-1" => {
                # Default item of tuners list:
                "name"       => _(
                  "Default (detected)"
                ),
                "parameters" => { "tuner" => "-1" }
              }
            }
          )
          Builtins.foreach(tuners) do |tuner|
            Ops.set(
              @tuners_by_id,
              [modul, Ops.get_string(tuner, ["parameters", "tuner"], "-2")],
              tuner
            )
          end
        end
      end
      if @tuners_database == nil
        # Error message popup:
        Report.Error(_("Unable to read the tuner database."))
        @tuners_database = {}
        return false
      end

      # translate it
      @tuners_database = Builtins.eval(@tuners_database)
      @tuners_by_id = Builtins.eval(@tuners_by_id)

      true
    end

    # Return description of one kernel module
    # @return [Hash]
    def GetKernelModuleInfo(modname)
      if @kernel_modules != nil
        if Builtins.haskey(@kernel_modules, modname)
          return Ops.get_map(@kernel_modules, modname, {})
        end
        if Builtins.haskey(@radio_modules, modname)
          return Ops.get_map(@radio_modules, modname, {})
        end
      end

      video_path = path(".modinfo.kernel.drivers.media.video")
      parm = Convert.to_map(SCR.Read(Builtins.add(video_path, modname)))
      parm == nil ? {} : parm
    end

    # Get a list of the available v4l kernel modules
    # and store it to <B>kernel_modules</B> map.
    # @return [Boolean] Returns <B>true</B>.
    def ReadKernelModules
      return true if @kernel_modules != nil

      video_path = path(".modinfo.kernel.drivers.media.video")
      @kernel_modules = {}
      modules_list = SCR.Dir(video_path)
      if modules_list == nil
        # Warning message popup:
        Report.Warning(
          _("Unable to read the list of\navailable kernel modules.")
        )
        return true
      end

      Builtins.foreach(
        Convert.convert(modules_list, :from => "list", :to => "list <string>")
      ) do |mod|
        parm = Convert.to_map(SCR.Read(Builtins.add(video_path, mod)))
        @kernel_modules = Builtins.add(@kernel_modules, mod, parm)
      end

      # add drivers from extra directory
      extra_path = path(".modinfo.updates")
      extra_modules_list = SCR.Dir(extra_path)
      if extra_modules_list != nil
        regexps = ["^ivtv", "^saa7"]

        extra_modules_list = Builtins.filter(extra_modules_list) do |m|
          found = false
          Builtins.foreach(regexps) do |regexp|
            found = true if Builtins.regexpmatch(m, regexp)
          end
          found
        end

        if Ops.greater_than(Builtins.size(extra_modules_list), 0)
          Builtins.y2debug("Extra kernel modules: %1", extra_modules_list)

          Builtins.foreach(extra_modules_list) do |mod|
            parm = Convert.to_map(SCR.Read(Builtins.add(video_path, mod)))
            @kernel_modules = Builtins.add(@kernel_modules, mod, parm)
          end
        end
      end

      Builtins.y2debug("All v4l kernel modules: %1", @kernel_modules)

      radio_path = path(".modinfo.kernel.drivers.media.radio")

      @radio_modules = {}
      modules_list = SCR.Dir(radio_path)
      if modules_list == nil
        # Warning message popup:
        Report.Warning(
          _("Unable to read the list of\navailable kernel modules.")
        )
        return true
      end

      Builtins.foreach(
        Convert.convert(modules_list, :from => "list", :to => "list <string>")
      ) do |mod|
        parm = Convert.to_map(SCR.Read(Builtins.add(radio_path, mod)))
        @radio_modules = Builtins.add(@radio_modules, mod, parm)
      end
      Builtins.y2debug("All radio kernel modules: %1", @radio_modules)

      dvb_path = path(".modinfo.kernel.drivers.media.dvb.frontends")

      @dvb_modules = {}
      modules_list = SCR.Dir(dvb_path)
      if modules_list == nil
        # Warning message popup:
        Report.Warning(
          _("Unable to read the list of\navailable kernel modules.")
        )
        return true
      end
      Builtins.foreach(
        Convert.convert(modules_list, :from => "list", :to => "list <string>")
      ) do |mod|
        parm = Convert.to_map(SCR.Read(Builtins.add(dvb_path, mod)))
        @dvb_modules = Builtins.add(@dvb_modules, mod, parm)
      end
      Builtins.y2debug("All dvb modules: %1", @dvb_modules)

      # read all DVB non-frontends drivers
      dvb_drivers_dir = path(".modinfo.kernel.drivers.media.dvb")
      dvb_drivers = SCR.Dir(dvb_drivers_dir)
      frontends = SCR.Dir(dvb_path)

      dvb_drivers = Builtins.filter(dvb_drivers) do |d|
        !Builtins.contains(frontends, d)
      end

      dvb_drivers = [] if dvb_drivers == nil

      @dvb_core_drivers = {}
      Builtins.foreach(dvb_drivers) do |mod|
        parm = Convert.to_map(SCR.Read(Builtins.add(dvb_drivers_dir, mod)))
        @dvb_core_drivers = Builtins.add(@dvb_core_drivers, mod, parm)
      end

      # add dvb drivers from media/video directory (search for "*dvb*" modules)
      dvb_extra_drivers = SCR.Dir(video_path)
      dvb_extra_drivers = Builtins.filter(dvb_extra_drivers) do |d|
        Builtins.issubstring(d, "dvb")
      end
      Builtins.y2milestone(
        "Extra DVB drivers (from media/video): %1",
        dvb_extra_drivers
      )

      if dvb_extra_drivers != nil &&
          Ops.greater_than(Builtins.size(dvb_extra_drivers), 0)
        Builtins.foreach(dvb_extra_drivers) do |mod|
          parm = Convert.to_map(SCR.Read(Builtins.add(video_path, mod)))
          @dvb_core_drivers = Builtins.add(@dvb_core_drivers, mod, parm)
        end
      end

      Builtins.y2debug("found dvb drivers: %1", @dvb_core_drivers)

      true
    end

    # Returns a list of all char-major-81-* in modprobe config file
    # @param [Yast::Path] mod_path path to agent (using modprobe.conf or modprobe.d/50-tv.conf)
    # @return [Array] List [ "char-major-81-0", "char-major-81-3" ] or so...
    def GetMajor81Aliases(mod_path)
      # get the specified char-major-81-*
      tv_aliases = SCR.Dir(Builtins.add(mod_path, "alias"))

      return [] if tv_aliases == nil

      Builtins.filter(
        Convert.convert(tv_aliases, :from => "list", :to => "list <string>")
      ) do |_alias|
        Ops.greater_than(Builtins.size(_alias), 13) &&
          Builtins.substring(_alias, 0, 13) == "char-major-81"
      end
    end

    # Returns a list of all char-major-212-* in modprobe config file
    # @param [Yast::Path] mod_path path to agent (using modprobe.conf or modprobe.d/50-tv.conf)
    # @return [Array] List [ "char-major-212-3" ] or so...
    def GetMajorInstalls(mod_path)
      # get the specified char-major-212-*
      tv_installs = SCR.Dir(Builtins.add(mod_path, "install"))

      return [] if tv_installs == nil

      major = "char-major-212"

      Builtins.filter(
        Convert.convert(tv_installs, :from => "list", :to => "list <string>")
      ) do |_alias|
        Ops.greater_than(Builtins.size(_alias), Builtins.size(major)) &&
          Builtins.substring(_alias, 0, Builtins.size(major)) == major
      end
    end

    # Read parameters of one module.
    # @param [Yast::Path] mod_path path to agent (using modprobe.conf or modprobe.d/50-tv.conf)
    # @param [String] module_name Name of the module
    # @return [Hash] Map with parameters
    # @example
    # $[ parameter_name: // parameter name
    #    $[ 0: nil,      // its value for 1st card
    #	     1: "3",      //               2nd card
    #	...
    def ReadModuleParameters(mod_path, module_name)
      options = {}
      opt_path = Builtins.add(mod_path, "options")
      if Builtins.contains(SCR.Dir(opt_path), module_name)
        options = Convert.to_map(SCR.Read(Builtins.add(opt_path, module_name)))
      end

      return {} if options == nil

      # Split the comma separated options into the needed map
      options = Builtins.mapmap(
        Convert.convert(options, :from => "map", :to => "map <string, string>")
      ) do |key, value|
        value = "" if value == nil
        values = Builtins.splitstring(value, ",")
        index = 0
        values_map = Builtins.listmap(
          Convert.convert(values, :from => "list", :to => "list <string>")
        ) do |val|
          ret = { index => val }
          index = Ops.add(index, 1)
          deep_copy(ret)
        end
        { key => values_map }
      end

      deep_copy(options)
    end

    def parse_module_string(input)
      ret = []

      return deep_copy(ret) if input == nil

      cmds = Builtins.splitstring(input, ";")

      Builtins.foreach(cmds) do |cmd|
        # TODO parse module parameters (in a separate function)
        mod_name = Builtins.regexpsub(
          cmd,
          "/sbin/modprobe[ \t]+([^ \t]*)",
          "\\1"
        )
        if mod_name == nil
          # only module name present
          mod_name = cmd
        end
        ret = Builtins.add(ret, mod_name)
      end 


      deep_copy(ret)
    end

    # Reads saved TV cards data from given file
    # @param [Yast::Path] mod_path path to agent (using modprobe.conf or modprobe.d/50-tv.conf)
    # @return [Array] of TV cards
    def read_modprobe(mod_path)
      if mod_path == path(".modprobe_tv") &&
          SCR.Read(path(".target.size"), "/etc/modprobe.d/50-tv.conf") == -1
        Builtins.y2milestone("creating /etc/modprobe.d/50-tv.conf...")
        SCR.Execute(
          path(".target.bash"),
          "/bin/touch /etc/modprobe.d/50-tv.conf"
        )
        return []
      end

      tv_cards = []

      alias_path = Builtins.add(mod_path, "alias")

      # get the specified char-major-81-*
      tv_aliases = GetMajor81Aliases(mod_path)
      tv_installs = GetMajorInstalls(mod_path)

      # the parameters read from modprobe.d/50-tv.conf
      # $[ "module" :  $[ parameter_name: $[ 0: nil, 1: "3", 2: "2" ] ] ]
      #                   no_of_the_card ----^-------^-------^
      modules_parameters = {}

      # Number of a card using this module
      # $[ "module" : integer ]
      modules_counts = {}

      # scan the video capture devices (major 81 and minor 0..63)
      card_no = 0
      while Ops.less_than(card_no, 128)
        _alias = Builtins.sformat("char-major-81-%1", card_no)
        if Builtins.contains(tv_aliases, _alias)
          card_name = ""
          unique_key = nil

          # get the module name
          module_name = Convert.to_string(
            SCR.Read(Builtins.add(alias_path, _alias))
          )
          Builtins.y2debug(
            "Reading alias %1: module name is '%2'",
            _alias,
            module_name
          )
          if module_name != nil && module_name != "" && module_name != "off"
            if Ops.get(modules_parameters, module_name) == nil
              Ops.set(
                modules_parameters,
                module_name,
                ReadModuleParameters(mod_path, module_name)
              )

              Ops.set(modules_counts, module_name, 0)
            end

            # get the name and unique key
            comment = Convert.to_string(
              SCR.Read(
                Builtins.add(Builtins.add(alias_path, _alias), "comment")
              )
            )
            name_and_uk = ModulesComments.ExtractFromComment(comment)

            if name_and_uk != nil
              card_name = Ops.get_string(name_and_uk, "name", "")
              unique_key = Ops.get_string(name_and_uk, "unique_key")
            end

            parameters = {}

            # read the parameters
            pars = Ops.get_map(modules_parameters, module_name, {})
            param_no = Ops.get_integer(modules_counts, module_name, 0)
            Ops.set(modules_counts, module_name, Ops.add(param_no, 1))
            pars = Builtins.mapmap(
              Convert.convert(pars, :from => "map", :to => "map <string, map>")
            ) do |key, value|
              { key => Ops.get_string(value, param_no, "") }
            end
            pars = Builtins.filter(
              Convert.convert(
                pars,
                :from => "map",
                :to   => "map <string, string>"
              )
            ) { |key, value| value != "" && value != nil }

            parameters = Builtins.add(parameters, module_name, pars)

            # fill the spaces in the cards
            while Ops.less_than(Builtins.size(tv_cards), card_no)
              tv_cards = Builtins.add(tv_cards, {})
            end

            radio = false
            radio = true if Ops.greater_than(card_no, 63)

            # add the card to the cards
            tv_cards = Builtins.add(
              tv_cards,
              {
                "name"       => card_name,
                "module"     => [module_name],
                "parameters" => parameters,
                "unique_key" => unique_key,
                "radio"      => radio
              }
            )
          end
        end
        card_no = Ops.add(card_no, 1)
      end
      Builtins.y2milestone(
        "The previously saved configuration (using '%1' path): %2",
        mod_path,
        tv_cards
      )


      # scan DVB devices (major 212 and minor 3, 65, ...)

      install_path = Builtins.add(mod_path, "install")
      card_no = 0
      while Ops.less_than(card_no, 4)
        minor = Ops.add(Ops.multiply(card_no, 64), 3)
        install = Builtins.sformat("char-major-212-%1", minor)
        if Builtins.contains(tv_installs, install)
          card_name = ""
          unique_key = nil

          # get the module name
          read_module_name = Convert.to_string(
            SCR.Read(Builtins.add(install_path, install))
          )

          module_names = parse_module_string(read_module_name)

          Builtins.y2milestone(
            "Reading install %1: module name is '%2'",
            install,
            module_names
          )
          if read_module_name != nil && read_module_name != ""
            Builtins.foreach(module_names) do |module_name|
              if Ops.get(modules_parameters, module_name) == nil
                Ops.set(
                  modules_parameters,
                  module_name,
                  ReadModuleParameters(mod_path, module_name)
                )

                Ops.set(modules_counts, module_name, 0)
              end
            end 


            # get the name and unique key
            comment = Convert.to_string(
              SCR.Read(
                Builtins.add(Builtins.add(install_path, install), "comment")
              )
            )
            name_and_uk = ModulesComments.ExtractFromComment(comment)

            if name_and_uk != nil
              card_name = Ops.get_string(name_and_uk, "name", "")
              unique_key = Ops.get_string(name_and_uk, "unique_key")
            end

            parameters = {}

            Builtins.foreach(module_names) do |module_name|
              # read the parameters
              pars = Ops.get_map(modules_parameters, module_name, {})
              param_no = Ops.get_integer(modules_counts, module_name, 0)
              Ops.set(modules_counts, module_name, Ops.add(param_no, 1))
              pars = Builtins.mapmap(
                Convert.convert(
                  pars,
                  :from => "map",
                  :to   => "map <string, map>"
                )
              ) do |key, value|
                { key => Ops.get_string(value, param_no, "") }
              end
              pars = Builtins.filter(
                Convert.convert(
                  pars,
                  :from => "map",
                  :to   => "map <string, string>"
                )
              ) { |key, value| value != "" && value != nil }
              parameters = Builtins.add(parameters, module_name, pars)
            end

            # fill the spaces in the cards
            while Ops.less_than(Builtins.size(tv_cards), card_no)
              tv_cards = Builtins.add(tv_cards, {})
            end

            readcard = {
              "name"       => card_name,
              "module"     => module_names,
              # !!! TODO: parameters for each kernel module
              "parameters" => parameters,
              "dvb"        => true,
              "unique_key" => unique_key,
              "radio"      => false
            }

            Builtins.foreach(
              Convert.convert(
                @dvb_cards_database,
                :from => "list",
                :to   => "list <map>"
              )
            ) do |vendor|
              cards = Ops.get_list(vendor, "cards", [])
              Builtins.foreach(cards) do |card|
                found_card = card_name
                db_card = Ops.get_string(card, "name")
                if found_card == db_card
                  # add card info without name
                  Builtins.y2milestone(
                    "found card in DB: %1",
                    Ops.get(card, "name")
                  )
                  card = Builtins.remove(card, "name")

                  Builtins.foreach(
                    Convert.convert(
                      card,
                      :from => "map",
                      :to   => "map <string, any>"
                    )
                  ) do |key, value|
                    if !Builtins.haskey(readcard, key)
                      Ops.set(readcard, key, value)
                    end
                  end 


                  Builtins.y2debug("readcard: %1", readcard)
                end
              end
            end 


            # add the card to the cards
            tv_cards = Builtins.add(tv_cards, readcard)
          end
        end
        card_no = Ops.add(card_no, 1)
      end

      Builtins.y2milestone(
        "The previously saved configuration (using '%1' path): %2",
        mod_path,
        tv_cards
      )

      deep_copy(tv_cards)
    end

    def IsFWInstalled(_FWpath)
      # is the firmware already installed?
      if Ops.greater_than(SCR.Read(path(".target.size"), _FWpath), 0)
        Builtins.y2milestone(
          "Required firmware (%1) is already installed",
          _FWpath
        )
        return true
      end

      false
    end

    def AskForFirmware(card, filename)
      return nil if filename == nil || filename == ""

      content = VBox(
        Label(
          Builtins.sformat(
            _(
              "Firmware must be installed for \n" +
                "TV card '%1' to work.\n" +
                "\n" +
                "Enter the location of the firmware file then\n" +
                "press Continue to install the firmware.\n"
            ),
            card
          )
        ),
        VSpacing(1),
        HBox(
          HSpacing(2),
          Frame(
            Id(:fr),
            _("Install Firmware"),
            HBox(
              TextEntry(Id(:firmware), Label.FileName, filename),
              VBox(Label(""), PushButton(Id(:browse), Label.BrowseButton))
            )
          ),
          HSpacing(2)
        ),
        VSpacing(1.5),
        ButtonBox(
          PushButton(Id(:cont), Opt(:default), Label.ContinueButton),
          PushButton(Id(:cancel), Label.CancelButton)
        ),
        VSpacing(0.5)
      )

      UI.OpenDialog(content)

      ui = nil
      file = filename

      while ui != :cont && ui != :cancel
        ui = Convert.to_symbol(UI.UserInput)

        if ui == :browse
          currentfile = Convert.to_string(UI.QueryWidget(Id(:firmware), :Value))
          # header in file selection popup
          newfile = UI.AskForExistingFile(
            currentfile,
            "*",
            _("Select Firmware File")
          )

          if newfile != nil
            UI.ChangeWidget(Id(:firmware), :Value, file)
            file = newfile
          end
        elsif ui == :cont
          file = Convert.to_string(UI.QueryWidget(Id(:firmware), :Value))
          # check whether file exists
          sz = Convert.to_integer(SCR.Read(path(".target.size"), file))

          if Ops.less_than(sz, 0)
            Report.Error(Message.CannotOpenFile(file))
            ui = :dummy
          end
        end
      end

      UI.CloseDialog
      ui != :cont ? nil : file
    end

    def AskForFirmwareCached(card, filename)
      ret = ""

      # is the file name in cache?
      if Builtins.haskey(@fw_source_cache, filename)
        ret = Ops.get(@fw_source_cache, filename, "")
      else
        ret = AskForFirmware(card, filename)

        # store the file name into cache
        Ops.set(@fw_source_cache, filename, ret) if ret != nil && ret != ""
      end

      ret
    end


    def InstallFWCard(source, target, offset, length, md5, ask)
      ret = false

      Builtins.y2milestone(
        "Installing firmware:  source: %1, target: %2, offset: %3, length: %4, md5: %5, ask: %6",
        source,
        target,
        offset,
        length,
        md5,
        ask
      )

      if IsFWInstalled(target)
        # the firmware is already installed
        return true
      end

      install = true

      if source != "" && source != nil
        if offset == 0 && length == nil
          # copy the firmware
          copy = Builtins.sformat("/bin/cp '%1' '%2'", source, target)
          result = Convert.to_integer(SCR.Execute(path(".target.bash"), copy))

          ret = result == 0
          Builtins.y2milestone(
            "copying firmware %1 -> %2 exit: %3",
            source,
            target,
            result
          )
        else
          # use dd to copy only required part of the file
          dd = Builtins.sformat(
            "/bin/dd bs=1 if=%1 of=%2 skip=%3 count=%4",
            source,
            target,
            offset,
            length
          )
          result = Convert.to_integer(SCR.Execute(path(".target.bash"), dd))

          ret = result == 0
          Builtins.y2milestone(
            "copying firmware %1 -> %2 (offset: %3, length: %4) exit: %5",
            source,
            target,
            offset,
            length,
            result
          )
        end
      else
        ret = false
      end

      if !ret && ask
        # firmware is not installed, display warning message
        Report.Warning(_("The TV card will not work without firmware."))
      end

      # check MD5 if it's specified and the firmware is installed
      if md5 != nil && md5 != "" && ret
        # compute MD5 hash of the firmware file
        md5cmd = Builtins.sformat("/usr/bin/md5sum %1", target)
        result = Convert.to_map(
          SCR.Execute(path(".target.bash_output"), md5cmd)
        )

        ret = Ops.get_integer(result, "exit", -1) == 0

        if ret == false
          if ask
            # warning popup - md5sum returned non-zero exit status
            Report.Warning(_("Could not check the MD5 sum of the firmware."))
          else
            Builtins.y2warning("Could not check MD5 sum of the firmware")
          end
        else
          # compare computed and expected MD5
          md5line = Ops.get(
            Builtins.splitstring(Ops.get_string(result, "stdout", ""), "\n"),
            0,
            ""
          )
          sum = Ops.get(Builtins.splitstring(md5line, " "), 0, "")

          if sum != md5
            Builtins.y2warning(
              "MD5sum of the firmware is incorrect (expected: %1, computed: %2)",
              sum,
              md5
            )

            # warning popup - computed and expected md5sum don't match
            if !ask ||
                !Popup.YesNo(
                  _(
                    "The MD5 check sum of the installed firmware\n" +
                      "does not match the value in the database. \n" +
                      "\n" +
                      "Use the firmware file anyway?\n"
                  )
                )
              # pressed 'NO' - remove the file
              rm = Builtins.sformat("/bin/rm %1", target)
              result2 = Convert.to_integer(
                SCR.Execute(path(".target.bash"), rm)
              )

              ret = false
              Builtins.y2milestone(
                "removing bad firmware file %1, exit: %2",
                target,
                result2
              )
            end
          else
            Builtins.y2debug(
              "MD5 sum (%1) matches the value in the database.",
              sum
            )
          end
        end
      end

      ret
    end

    # Return list of kernel modules required by configured cards
    # @return list List of kernel modules
    def RequiredModules(ko_suffix)
      reqmodules = []

      # get all required modules
      Builtins.foreach(
        Convert.convert(@cards, :from => "list", :to => "list <map>")
      ) do |card|
        m = Ops.get_list(card, "module", [])
        if m != nil && Ops.greater_than(Builtins.size(m), 0)
          # add .ko extension to kernel module name
          m = Builtins.maplist(m) do |mod|
            mod = Ops.add(mod, ".ko") if ko_suffix
            mod
          end
          reqmodules = Convert.convert(
            Builtins.merge(reqmodules, m),
            :from => "list",
            :to   => "list <string>"
          )
        end
      end 


      # remove duplicates
      reqmodules = Builtins.toset(reqmodules)

      Builtins.y2milestone("required kernel modules: %1", reqmodules)

      deep_copy(reqmodules)
    end

    def FirmwareDrivers
      Builtins.maplist(
        Convert.convert(
          @firmware_database,
          :from => "map",
          :to   => "map <string, list>"
        )
      ) { |modname, fws| modname }
    end

    # Install firmware for all configured cards
    # @return [Boolean] True on success
    def InstallFW
      ret = true

      # get all required modules
      reqmod = RequiredModules(false)

      # get all modules whoch require firmware
      fwmod = FirmwareDrivers()

      # check whether there is a driver which requires firmware
      reqmod = Builtins.filter(reqmod) { |r| Builtins.contains(fwmod, r) }

      Builtins.y2milestone("required modules with FW: %1", reqmod)

      packages_to_install = []

      if Ops.greater_than(Builtins.size(reqmod), 0)
        Builtins.foreach(reqmod) do |drv|
          # find card that requires the driver
          cardname = "TV"
          # is the firmware really needed?
          firmware_needed = nil
          Builtins.foreach(
            Convert.convert(@cards, :from => "list", :to => "list <map>")
          ) do |card|
            drvs = Ops.get_list(card, "module", [])
            if Builtins.contains(drvs, drv)
              cardname = Ops.get_string(card, "name", "TV")

              # install the firmware?
              inst = Ops.get_boolean(card, "fw_install", true)
              if firmware_needed == nil
                firmware_needed = inst
              else
                firmware_needed = firmware_needed || inst
              end
            end
          end
          if firmware_needed == false
            Builtins.y2milestone(
              "Skipping firmware installation for driver '%1' (card '%2')",
              drv,
              cardname
            )
            next
          end
          fws = Ops.get_list(@firmware_database, drv, [])
          Builtins.foreach(fws) do |fw|
            required_packages = Ops.get_list(fw, "packages", [])
            if Ops.greater_than(Builtins.size(required_packages), 0)
              Builtins.y2milestone(
                "Driver %1 requires these packages: %2",
                drv,
                required_packages
              )
              packages_to_install = Convert.convert(
                Builtins.union(packages_to_install, required_packages),
                :from => "list",
                :to   => "list <string>"
              )
            end
            target = Ops.get_string(fw, "target", "")
            source = Ops.get_string(fw, "source", "")
            if target != nil && target != "" && source != nil && source != ""
              inst = IsFWInstalled(Ops.add(@firmware_prefix, target))
              if inst
                # the firmware is already installed
                Builtins.y2milestone(
                  "Firmware %1 has been already installed.",
                  Ops.add(@firmware_prefix, target)
                )
                next
              end

              install = true

              # install fw in a loop until it succeeds or a wrong fw is confirmed
              while install
                firmware_source = AskForFirmwareCached(cardname, source)
                firmware_target = Ops.add(@firmware_prefix, target)

                info = Ops.get_list(fw, "info", [])
                info_size = Builtins.size(info)

                Builtins.y2debug("info_size: %1", info_size)
                Builtins.y2debug("info: %1", info)

                if Ops.greater_than(info_size, 1)
                  index = 0

                  while Ops.less_than(index, info_size)
                    inf = Ops.get(info, index, {})
                    Builtins.y2milestone("Using FW info[%1]: %2", index, inf)

                    offset = Ops.get_integer(inf, "offset", 0)
                    length = Ops.get_integer(inf, "length")
                    md5 = Ops.get_string(inf, "md5sum", "")

                    if !InstallFWCard(
                        firmware_source,
                        firmware_target,
                        offset,
                        length,
                        md5,
                        Ops.add(index, 1) == info_size
                      )
                      ret = false
                      index = Ops.add(index, 1)
                    else
                      # installation was successful, skip all other versions
                      index = info_size
                      ret = true
                    end
                  end
                else
                  if !InstallFWCard(
                      firmware_source,
                      firmware_target,
                      0,
                      nil,
                      "",
                      true
                    )
                    ret = false
                  end
                end

                if ret == false
                  # try installation of the firmware again?
                  install = Popup.YesNo(
                    _(
                      "Installation of the firmware has failed.\nTry the installation again?"
                    )
                  )

                  if Builtins.haskey(@fw_source_cache, source) &&
                      @fw_source_cache != nil
                    # remove the invalid file from the cache
                    @fw_source_cache = Builtins.remove(@fw_source_cache, source)
                  end
                else
                  install = false
                end
              end
            end
          end
        end 


        Builtins.y2milestone("Collected packages: %1", packages_to_install)

        if Ops.greater_than(Builtins.size(packages_to_install), 0)
          # do not install the packages again
          packages_to_install = Builtins.filter(packages_to_install) do |pkg|
            !Package.Installed(pkg)
          end

          Builtins.y2milestone("Packages to install: %1", packages_to_install)

          if Ops.greater_than(Builtins.size(packages_to_install), 0)
            ret = ret && Package.DoInstall(packages_to_install)
          end
        end
      end

      ret
    end


    # Fill the map of all tv settings from the SCR.
    # @return [Boolean] Was the reading succesfull?
    def ReadSettings
      @cards = read_modprobe(path(".modprobe_tv"))

      if Ops.less_than(Builtins.size(@cards), 1)
        @cards = read_modprobe(path(".modules"))
        @used_modprobe_conf = true if Ops.greater_than(Builtins.size(@cards), 0)
      end

      # Read user settings ("Do not ask again")
      @not_ask = ReadUserSettings()

      true
    end

    # Writes parameters of the modules. As an input, it uses a map
    # with modules and all their parameters:
    # <PRE>
    # $[ "module" :	       // name of the module
    #     [ no_last_param,	// number of cards using this modules
    #	 $[ parameter_name:  // parameter name
    #	     $[ 0: nil,      // its value for 1st card
    #		1: "3",      //	       2nd card
    # </PRE>
    # @param [Hash] modules_parameters Map with the modules and parameters
    # @return [Boolean] Was the write successful?
    def WriteModulesParameters(modules_parameters)
      modules_parameters = deep_copy(modules_parameters)
      return true if modules_parameters == nil

      Builtins.y2debug("write modules_parameters: %1", modules_parameters)

      result = true
      Builtins.foreach(
        Convert.convert(
          modules_parameters,
          :from => "map",
          :to   => "map <string, list>"
        )
      ) do |module_name, params_with_no|
        param_values = ""
        parameter_counter = Ops.get_integer(params_with_no, 0, 0)
        parameter_counter = 0 if parameter_counter == nil
        parameters = Ops.get_map(params_with_no, 1, {})
        parameters = {} if parameters == nil
        Builtins.y2debug("parameters: %1", parameters)
        parameters = Builtins.mapmap(
          Convert.convert(
            parameters,
            :from => "map",
            :to   => "map <string, map>"
          )
        ) do |param_name, param_map|
          param_map = {} if param_map == nil
          # fill the holes in param_map and store the values
          param_values2 = []
          count = 0
          while Ops.less_than(count, parameter_counter)
            value = Ops.get_string(param_map, count, "")
            # this is a hack for detected cards (see bug #24132)
            # check if there are more cards, prevent storing value -1 which can cause problems
            if (value == nil || value == "") &&
                Ops.greater_than(parameter_counter, 1)
              value = "-1"
            end
            param_values2 = Builtins.add(param_values2, value)
            count = Ops.add(count, 1)
          end
          { param_name => Builtins.mergestring(param_values2, ",") }
        end
        Builtins.y2debug("parameters: %1", parameters)
        # remove empty parameters
        parameters = Builtins.filter(
          Convert.convert(
            parameters,
            :from => "map",
            :to   => "map <string, string>"
          )
        ) { |modname, opts| opts != nil && opts != "" }
        Builtins.y2debug("parameters: %1", parameters)
        Builtins.y2milestone(
          "Saving options '%1' for module '%2'",
          parameters,
          module_name
        )
        if parameters == {} || parameters == nil
          # We have to empty the options...
          if Builtins.contains(
              SCR.Dir(path(".modprobe_tv.options")),
              module_name
            )
            SCR.Write(
              Builtins.add(path(".modprobe_tv.options"), module_name),
              nil
            )
          end
        else
          # Write it...
          Builtins.y2milestone("pars=%1, name=%2", parameters, module_name)
          result = result &&
            SCR.Write(
              Builtins.add(path(".modprobe_tv.options"), module_name),
              parameters
            )
        end
      end
      result
    end

    def GetStaticConfig(uniq)
      file = ""

      # get all static configurations
      configs = HWConfig.ConfigFiles
      configs = Builtins.filter(configs) do |f|
        Builtins.regexpmatch(f, "^static-[0-9]*")
      end
      Builtins.y2milestone("found static configs: %1", configs)

      # search existing config file
      if Ops.greater_than(Builtins.size(configs), 0)
        greatest = -1
        found = false

        # search existing config
        Builtins.foreach(configs) do |f|
          if !found
            # read MODULE comment
            comment = HWConfig.GetComment(f, "MODULE")

            if comment != nil && comment != ""
              # search for uniqID
              if Builtins.regexpmatch(comment, uniq)
                file = f
                found = true
                Builtins.y2milestone("Found flags in file: %1", f)
              end
            end

            if !found
              # not found, check config number
              num = Builtins.regexpsub(f, "^static-([0-9]*)", "\\1")

              if num != nil
                num_i = Builtins.tointeger(num)
                if num_i != nil && Ops.greater_than(num_i, greatest)
                  greatest = num_i
                end
              end
            end
          end
        end 


        if file == nil || file == ""
          Builtins.y2debug("file empty, greatest: %1", greatest)
          # not found - create new config
          file = Builtins.sformat("static-%1", Ops.add(greatest, 1))
        end
      else
        file = "static-0"
      end

      file
    end


    # Removes all hwcfg files created by this module (they are not needed anymore)
    def RemoveHWConfigTV
      ret = true

      # get list of all config files
      cfiles = HWConfig.ConfigFiles
      Builtins.y2milestone("Found sysconfig/hardware files: %1", cfiles)

      if Ops.greater_than(Builtins.size(cfiles), 0)
        changed = false

        # scan each config file - search for sound card config
        Builtins.foreach(cfiles) do |cfile|
          com = HWConfig.GetComment(cfile, "MODULE")
          if com != nil
            coms = Builtins.splitstring(com, "\n")

            Builtins.foreach(coms) do |comline|
              # this is a hwconfig file crated by Yast
              # we can safely remove it
              if Builtins.regexpmatch(comline, "^# YaST configured TV card")
                Builtins.y2milestone("Removing file: %1", cfile)
                ret = HWConfig.RemoveConfig(cfile) && ret
                changed = true
              end
            end
          end
        end

        if changed
          # apply the changes
          HWConfig.Flush
        end
      end

      ret
    end

    # initialize the blacklists from /etc/modprobe.d/50-blacklist.conf file
    def LoadBlackList
      if @blacklisted_aliases == nil
        @blacklisted_aliases = SCR.Dir(path(".modprobe_blacklist.alias"))

        # leave only "bttv_skip_it" aliases, the others might be needed...
        @blacklisted_aliases = Builtins.filter(@blacklisted_aliases) do |modalias|
          Convert.to_string(
            SCR.Read(Ops.add(path(".modprobe_blacklist.alias"), modalias))
          ) == "bttv_skip_it"
        end

        @blacklisted_aliases = [] if @blacklisted_aliases == nil

        Builtins.y2milestone("Loaded alias blacklist: %1", @blacklisted_aliases)
      end

      if @blacklisted_modules == nil
        # driver blacklist
        @blacklisted_modules = SCR.Dir(path(".modprobe_blacklist.blacklist"))

        @blacklisted_modules = [] if @blacklisted_modules == nil

        Builtins.y2milestone(
          "Loaded modules blacklist: %1",
          @blacklisted_modules
        )
      end

      nil
    end

    # is the driver blacklisted?
    def IsDriverBlacklisted(driver)
      LoadBlackList()

      ret = Builtins.contains(@blacklisted_modules, driver)

      Builtins.y2warning("Driver '%1' is blacklisted", driver) if ret

      ret
    end

    # is any driver from the list blacklisted?
    def AnyDriverBlacklisted(drivers)
      drivers = deep_copy(drivers)
      Builtins.foreach(drivers) { |drv| next true if IsDriverBlacklisted(drv) } 


      false
    end

    # is the card blacklisted using modalias?
    def IsModaliasBlacklisted(_alias)
      LoadBlackList()

      ret = Builtins.contains(@blacklisted_aliases, _alias)

      Builtins.y2warning("Modalias '%1' is blacklisted", _alias) if ret

      ret
    end

    # is the card blacklisted? (is a driver or the modalias of the card blacklisted?)
    def IsCardBlacklisted(card)
      card = deep_copy(card)
      # the card is blacklisted when it is in the modalias blacklist
      # or at least one driver is blacklisted
      ret = IsModaliasBlacklisted(Ops.get_string(card, "modalias", "")) ||
        AnyDriverBlacklisted(Ops.get_list(card, "module", []))

      if ret
        Builtins.y2warning(
          "Card '%1' is blacklisted",
          Ops.get_string(card, "name", "")
        )
      end

      ret
    end


    # Remove the configured cards from the blacklist (/etc/modprobe.d/blacklist) to enable
    # automatic module loading after reboot of the system (see bug #330109).
    def FixBlackListFile
      blacklist_changed = false

      # initialize the blacklists when needed
      LoadBlackList()

      Builtins.foreach(
        Convert.convert(@cards, :from => "list", :to => "list <map>")
      ) do |card|
        card_modalias = Ops.get_string(card, "modalias", "")
        # check modalias blacklist
        if IsModaliasBlacklisted(card_modalias)
          Builtins.y2warning(
            "Removing modalias '%1' (card '%2') from the blacklist",
            card_modalias,
            Ops.get_string(card, "name", "")
          )

          # remove the modalias from the blacklist
          SCR.Write(
            Ops.add(path(".modprobe_blacklist.alias"), card_modalias),
            nil
          )

          blacklist_changed = true
        end
        # check all drivers
        Builtins.foreach(Ops.get_list(card, "module", [])) do |mod|
          if IsDriverBlacklisted(mod)
            Builtins.y2warning(
              "Removing module '%1' (card '%2') from the blacklist",
              mod,
              Ops.get_string(card, "name", "")
            )

            # remove the module from the blacklist
            SCR.Write(Ops.add(path(".modprobe_blacklist.blacklist"), mod), nil)

            blacklist_changed = true
          end
        end
      end 


      # flush the changes
      SCR.Write(path(".modprobe_blacklist"), nil) if blacklist_changed

      nil
    end


    # Write the TV settings to the SCR.
    # @return [Boolean] Was the reading successful?
    def WriteSettings
      # common settings
      Builtins.y2debug(
        "Writing char-major-81 (videodev) to /etc/modprobe.d/50-tv.conf"
      )
      SCR.Write(path(".modprobe_tv.alias.\"char-major-81\""), "videodev")

      # reset the old settings (all char-major-81-* aliases)
      Builtins.foreach(GetMajor81Aliases(path(".modprobe_tv"))) do |_alias|
        SCR.Write(Builtins.add(path(".modprobe_tv.alias"), _alias), nil)
      end
      if @used_modprobe_conf
        Builtins.y2milestone(
          "removing old tv configuration from /etc/modprobe.conf (it will be saved to /etc/modprobe.d/50-tv.conf)"
        )
        # remove aliases from old config file
        Builtins.foreach(GetMajor81Aliases(path(".modules"))) do |_alias|
          SCR.Write(Builtins.add(path(".modules.alias"), _alias), nil)
        end
        # remove options from old config file
        Builtins.foreach(
          Convert.convert(@cards, :from => "list", :to => "list <map>")
        ) do |card|
          module_names = Ops.get_list(card, "module", [])
          module_name = Ops.get(
            module_names,
            Ops.subtract(Builtins.size(module_names), 1),
            ""
          )
          if Builtins.contains(SCR.Dir(path(".modules.options")), module_name)
            SCR.Write(Builtins.add(path(".modules.options"), module_name), nil)
          end
        end
        SCR.Write(Builtins.add(path(".modules.options"), "i2c-algo-bit"), nil)
      end

      # fix of bug #19122:
      # message "modprobe: Can't locate module char-major-81-1" when second
      # tv card not present -> setting non-existing cards as "off"
      i = 0
      while Ops.less_than(i, 4)
        _alias = Builtins.sformat("char-major-81-%1", i)
        SCR.Write(Builtins.add(path(".modprobe_tv.alias"), _alias), "off")
        i = Ops.add(i, 1)
      end

      # for cards choosed to delete...
      Builtins.foreach(
        Convert.convert(
          @cards_to_del,
          :from => "list",
          :to   => "list <map <string, any>>"
        )
      ) do |card|
        module_names = Ops.get_list(card, "module", [])
        Builtins.foreach(module_names) do |module_name|
          next if module_name == ""
          if Builtins.contains(
              SCR.Dir(path(".modprobe_tv.options")),
              module_name
            )
            Builtins.y2milestone(
              "Deleting module %1 from /etc/modprobe.d/50-tv.conf",
              module_name
            )
            # ... delete module's options from modprobe file
            SCR.Write(
              Builtins.add(path(".modprobe_tv.options"), module_name),
              nil
            )
          end
          # ... and unload the module from kernel
          SCR.Execute(
            path(".target.bash"),
            Builtins.sformat("/sbin/rmmod %1", module_name),
            {}
          )
        end
        if Ops.greater_than(Builtins.size(module_names), 1)
          # remove install line
          installs = SCR.Dir(path(".modprobe_tv.install"))

          if installs != nil && Ops.greater_than(Builtins.size(installs), 0)
            # search deleted card
            Builtins.foreach(installs) do |major|
              p = @used_modprobe_conf ? path(".modules") : path(".modprobe_tv")
              # get the name and unique key
              comment = Convert.to_string(
                SCR.Read(
                  Ops.add(
                    Ops.add(Ops.add(p, path(".install")), major),
                    "comment"
                  )
                )
              )
              name_and_uk = ModulesComments.ExtractFromComment(comment)
              Builtins.y2debug("comment: %1", name_and_uk)
              if Ops.get_string(card, "unique_key") ==
                  Ops.get_string(name_and_uk, "unique_key", "")
                Builtins.y2milestone("removing install %1", major)
                SCR.Write(Ops.add(Ops.add(p, path(".install")), major), nil)
              end
            end
          end
        end
      end

      # remove hwcfg files (not needed anymore)
      RemoveHWConfigTV()

      result = true

      # save the status (configured/unconfigured)
      probe_status = Builtins.listmap(
        Convert.convert(
          @detected_cards,
          :from => "list",
          :to   => "list <map <string, any>>"
        )
      ) { |card| { Ops.get_string(card, "unique_key") => :no } }

      # store the parameters to write to this variable
      # $[ "module" :
      #	[ no_last_param, $[ parameter_name: $[0: nil, 1: "3", 2: "2"]]]]
      #                         no_of_the_card ----^-------^-------^
      modules_parameters = {}

      # commands to start the devices $[ "device_name" : "commmand" ]
      start_commands = []

      # do this for each card...
      tv_card_no = 0
      radio_card_no = 64
      dvb_card_no = 0
      Builtins.foreach(
        Convert.convert(@cards, :from => "list", :to => "list <map>")
      ) do |card|
        Builtins.y2milestone("Writing configuration of card: %1", card)
        radio = Ops.get_boolean(card, "radio", false)
        module_names = Ops.get_list(card, "module", [])
        card_name = Ops.get_string(card, "name", "Manually added card")
        dvb = Ops.get_boolean(card, "dvb", false)
        unique_key = Ops.get_string(
          card,
          "unique_key",
          dvb ?
            Builtins.sformat("dvb.nouniqkey%1", dvb_card_no) :
            Builtins.sformat(
              "tv.nouniqkey%1",
              radio ? radio_card_no : tv_card_no
            )
        )
        if module_names != nil && module_names != []
          _alias = Builtins.sformat(
            "char-major-81-%1",
            radio ? radio_card_no : tv_card_no
          )

          if dvb
            _alias = Builtins.sformat(
              "char-major-212-%1",
              Ops.add(Ops.multiply(64, dvb_card_no), 3)
            )
          end

          Builtins.y2milestone(
            "Writing alias %2 %1 to /etc/modprobe.d/50-tv.conf",
            module_names,
            _alias
          )

          # modprobe comment
          comment = Ops.add(
            radio ?
              "# YaST configured radio card\n" :
              "# YaST configured TV card\n",
            ModulesComments.StoreToComment(card_name, unique_key)
          )

          if Builtins.size(module_names) == 1
            # write alias
            SCR.Write(
              Builtins.add(path(".modprobe_tv.alias"), _alias),
              Ops.get(module_names, 0, "")
            )
            start_commands = Builtins.add(
              start_commands,
              {
                "model" => card_name,
                "cmd"   => Builtins.sformat(
                  "/sbin/rmmod '%1' 2> /dev/null; /sbin/modprobe '%1'",
                  String.Quote(Ops.get(module_names, 0, ""))
                )
              }
            )
          elsif Ops.greater_than(Builtins.size(module_names), 1)
            install_string = ""
            index = 0

            Builtins.foreach(module_names) do |m|
              if Ops.greater_than(Builtins.size(install_string), 0)
                install_string = Ops.add(install_string, "; ")
              end
              install_string = Ops.add(
                install_string,
                Builtins.sformat(
                  "/sbin/rmmod '%1' 2> /dev/null; /sbin/modprobe '%1'",
                  String.Quote(m)
                )
              )
              index = Ops.add(index, 1)
            end 


            start_commands = Builtins.add(
              start_commands,
              { "model" => card_name, "cmd" => install_string }
            )
            SCR.Write(
              Builtins.add(path(".modprobe_tv.install"), _alias),
              install_string
            )
          else
            Builtins.y2warning("List of kernel modules is empty!")
          end

          # store parameters to "modules_parameters"
          mods = Ops.get_list(card, "module", [])

          # process all modules used by the card
          Builtins.foreach(mods) do |module_name|
            params_with_no = Ops.get_list(modules_parameters, module_name, [])
            parameter_counter = Ops.get_integer(params_with_no, 0, 0)
            parameters = Ops.get_map(params_with_no, 1, {})
            Builtins.foreach(Ops.get_map(card, ["parameters", module_name], {})) do |param_name, param_val|
              # add the parameter to "parameters" map
              param_map = Ops.get_map(parameters, param_name, {})
              Ops.set(param_map, parameter_counter, param_val)
              Ops.set(parameters, param_name, param_map)
            end
            parameter_counter = Ops.add(parameter_counter, 1)
            Ops.set(
              modules_parameters,
              module_name,
              [parameter_counter, parameters]
            )
          end 


          # write comment with unique key and the card name
          Builtins.y2debug(
            "Writing comment to alias %1 in /etc/modprobe.d/50-tv.conf",
            _alias
          )

          modpath = Ops.greater_than(Builtins.size(module_names), 1) ?
            path(".install") :
            path(".alias")
          SCR.Write(
            Builtins.add(
              Builtins.add(Ops.add(path(".modprobe_tv"), modpath), _alias),
              "comment"
            ),
            comment
          )

          # set the appropriate unique key as configured
          Ops.set(probe_status, unique_key, :yes)
        end
        if radio
          radio_card_no = Ops.add(radio_card_no, 1)
        elsif dvb
          dvb_card_no = Ops.add(dvb_card_no, 1)
        else
          tv_card_no = Ops.add(tv_card_no, 1)
        end
      end

      # write the parameters
      if !WriteModulesParameters(modules_parameters)
        # Error message popup, %1 is file name
        Report.Error(
          Builtins.sformat(
            _("Unable to write parameters\nto %1."),
            "/etc/modprobe.d/50-tv.conf"
          )
        )
        result = false
      end

      # write unique keys
      Builtins.foreach(
        Convert.convert(
          probe_status,
          :from => "map",
          :to   => "map <string, symbol>"
        )
      ) do |uk, status|
        SCR.Write(path(".probe.status.configured"), uk, status) if uk != nil
      end

      # write modules
      if !SCR.Write(path(".modprobe_tv"), nil)
        # Error message popup,  %1 is file name
        Report.Error(
          Builtins.sformat(
            _("Unable to write %1."),
            "/etc/modprobe.d/50-tv.conf"
          )
        )
        result = false
      end

      if @used_modprobe_conf && !SCR.Write(path(".modules"), nil)
        # Error message popup,  %1 is file name
        Report.Error(
          Builtins.sformat(_("Unable to write %1."), "/etc/modprobe.conf")
        )
        result = false
      end

      # start up the configured devices
      Builtins.foreach(start_commands) do |dev|
        Builtins.y2milestone(
          "Starting card %1: %2",
          Ops.get(dev, "model", ""),
          Ops.get(dev, "cmd", "")
        )
        res = Convert.to_integer(
          SCR.Execute(path(".target.bash"), Ops.get(dev, "cmd", ""))
        )
        if res != 0
          Report.Error(
            Builtins.sformat(
              _("Cannot start device %1."),
              Ops.get(dev, "model", "")
            )
          )
          result = false
        end
      end 


      # Remove the configured cards from the blacklist file,
      # enable automatic loading after reboot.
      # NOTE: Do this AFTER loading the drivers in the previous code!
      # (When a blacklisted module freezes the system it will not be loaded
      # automatically after reboot.)
      FixBlackListFile()

      result
    end

    # Write the sound settings needed for TV to the SCR.
    # @return [Boolean] Was the reading succesfull?
    def WriteSoundVolume
      # unmute the sound cards
      Builtins.foreach(
        Convert.convert(
          @cards,
          :from => "list",
          :to   => "list <map <string, any>>"
        )
      ) do |card|
        sound_card_no = Ops.get_integer(card, "sound_card_no")
        if sound_card_no != nil
          Sound.SetVolume(sound_card_no, "Line", 80)
          Sound.SetVolume(sound_card_no, "Video", 80)
        end # NOTE: it is not important to save the attached sound card number!
      end

      SaveVolume()
    end

    # Scan for the TV cards.
    # @return [Boolean] Return false if the module should be terminated.
    def Detect
      # Confirmation: label text (detecting hardware: xxx)
      if !Confirm.Detection(_("TV cards"), "yast-tv")
        @detected_cards = []
        return true
      end

      probe_tv = Convert.to_list(SCR.Read(path(".probe.tv")))
      Builtins.y2milestone(".probe.tv: %1", probe_tv)
      if probe_tv == nil
        # Warning message popup (detection problem):
        Report.Warning(_("Unable to probe the TV cards."))
        Builtins.y2warning("Cannot probe TV cards: Read(.probe.tv) is nil.")
        @detected_cards = []
        return true
      end

      # probe for DVB cards
      probe_dvb = Convert.convert(
        SCR.Read(path(".probe.dvb")),
        :from => "any",
        :to   => "list <map>"
      )
      Builtins.y2milestone(".probe.dvb: %1", probe_dvb)

      if probe_dvb == nil
        # Warning message popup (detection problem):
        Report.Warning(_("Unable to probe the DVB cards."))
        Builtins.y2warning("Cannot probe TV cards: Read(.probe.dvb) is nil.")
        @detected_cards = []
        return true
      end

      # add DVB data to each DVB TV card
      probe_dvb = Builtins.maplist(probe_dvb) do |dvb_card|
        Ops.set(dvb_card, "dvb", true)
        deep_copy(dvb_card)
      end

      probe_tv = Builtins.merge(probe_tv, probe_dvb)

      @detected_cards = []

      Builtins.foreach(
        Convert.convert(
          probe_tv,
          :from => "list",
          :to   => "list <map <string, any>>"
        )
      ) do |tv_card|
        result = {}
        # look for the name of the card
        card_name = Ops.get_string(tv_card, "sub_device", "")
        if card_name == nil || card_name == ""
          card_name = Ops.get_string(tv_card, "device", "")
        end
        result = Builtins.add(result, "name", card_name)
        # look for the unique id
        unique_key = Ops.get_string(tv_card, "unique_key")
        if unique_key != nil
          result = Builtins.add(result, "unique_key", unique_key)
        end
        modalias = Ops.get_string(tv_card, "modalias")
        result = Builtins.add(result, "modalias", modalias) if modalias != nil
        # add DVB flag and info from DB
        if Ops.get_boolean(tv_card, "dvb", false)
          Ops.set(result, "dvb", true)
          foundDB = false

          Builtins.foreach(
            Convert.convert(
              @dvb_cards_database,
              :from => "list",
              :to   => "list <map>"
            )
          ) do |vendor|
            cards = Ops.get_list(vendor, "cards", [])
            Builtins.foreach(cards) do |card|
              found_card = Ops.get_string(result, "name", "")
              db_card = Ops.get_string(card, "name")
              if found_card == db_card
                # add card info without name
                Builtins.y2milestone(
                  "found card in DB: %1",
                  Ops.get(card, "name")
                )
                card = Builtins.remove(card, "name")

                Builtins.foreach(
                  Convert.convert(
                    card,
                    :from => "map",
                    :to   => "map <string, any>"
                  )
                ) { |key, value| Ops.set(result, key, value) } 


                Builtins.y2debug("result: %1", result)

                foundDB = true
              end
            end
          end 


          Ops.set(result, "unknown", true) if foundDB == false
        end
        # look for the module
        drivers = Ops.get_list(tv_card, "drivers", [])
        # don't override drivers data from DB
        if Ops.greater_than(Builtins.size(drivers), 0) &&
            !Builtins.haskey(result, "module")
          modules_list = Ops.get_list(drivers, [0, "modules"], [])
          modules_list = Builtins.filter(Ops.get_list(modules_list, 0, [])) do |mod|
            mod != nil && mod != ""
          end

          Builtins.y2debug("modules_list: %1", modules_list)

          if Ops.greater_than(Builtins.size(modules_list), 0)
            result = Builtins.add(result, "module", modules_list)
          end
        end
        subdevice = Ops.get_integer(tv_card, "sub_device_id", -1)
        subvendor = Ops.get_integer(tv_card, "sub_vendor_id", -1)
        if subdevice != -1 && subvendor != -1
          card_id = Ops.bitwise_or(Ops.shift_left(subdevice, 16), subvendor)
          card_id = Ops.add(
            Ops.bitwise_and(card_id, 4294901760),
            Ops.bitwise_and(card_id, 65535)
          )
          result = Builtins.add(result, "card_id", card_id)
        end
        @detected_cards = Builtins.add(@detected_cards, result)
      end

      Builtins.y2milestone("Detected cards: %1", @detected_cards)
      Builtins.y2milestone("Cards: %1", @cards)
      true
    end

    # Returns a list with the overview of the installed cards.
    # It can be used in Summary::DevicesList().
    # @return [Array] Description of the installed cards
    def InstalledCardsSummary
      installed_list = []

      if Ops.greater_than(Builtins.size(@cards), 0)
        card_no = 0
        dvbcard_no = 0
        installed_list = Builtins.maplist(
          Convert.convert(@cards, :from => "list", :to => "list <map>")
        ) do |card|
          card_item = nil
          name = Ops.get_string(card, "name")
          if name != nil
            installed_str = ""

            if Ops.get_boolean(card, "radio", false)
              installed_str = Builtins.sformat(
                # Summary text (%1 is number)
                _("Installed as radio card number %1."),
                card_no
              )
            elsif Ops.get_boolean(card, "dvb", false)
              installed_str = Builtins.sformat(
                # Summary text (%1 is number)
                _("Installed as DVB card number %1."),
                dvbcard_no
              )
            else
              installed_str = Builtins.sformat(
                # Summary text (%1 is number)
                _("Installed as TV card number %1"),
                card_no
              )
            end

            if @firmware_database != nil &&
                Ops.greater_than(Builtins.size(@firmware_database), 0)
              Builtins.foreach(
                Convert.convert(
                  @firmware_database,
                  :from => "map",
                  :to   => "map <string, list <map <string, any>>>"
                )
              ) do |fwmod, fws|
                if Builtins.contains(Ops.get_list(card, "module", []), fwmod)
                  Builtins.foreach(fws) do |fw|
                    target = Ops.get_string(fw, "target", "")
                    source = Ops.get_string(fw, "source", "")
                    if target != "" && source != ""
                      inst = IsFWInstalled(Ops.add(@firmware_prefix, target))

                      installed_str = Ops.add(
                        Ops.add(Ops.add(installed_str, "<BR>"), _("Firmware: ")),
                        inst ?
                          Builtins.sformat(_("Installed (%1)"), target) :
                          Builtins.sformat(_("Not installed (%1)"), source)
                      )
                    end
                    # add packages
                    required_packages = Ops.get_list(fw, "packages", [])
                    if Ops.greater_than(Builtins.size(required_packages), 0)
                      Builtins.y2milestone(
                        "Required packages for driver %1: %2",
                        fwmod,
                        required_packages
                      )
                    end
                    Builtins.foreach(required_packages) do |pkg|
                      # summary string, %1 is a package name, %2 is a status string: installed
                      installed_str = Ops.add(
                        Ops.add(installed_str, "<BR>"),
                        Builtins.sformat(
                          _("Package: %1 (%2)"),
                          # package status
                          pkg,
                          Package.Installed(pkg) ?
                            _("Installed") :
                            _("Not Installed")
                        )
                      )
                    end
                  end
                end
              end
            end

            card_item = Summary.Device(name, installed_str)
          end
          if Ops.get_boolean(card, "dvb", false)
            dvbcard_no = Ops.add(dvbcard_no, 1)
          else
            card_no = Ops.add(card_no, 1)
          end
          card_item
        end

        # Filter out nils
        installed_list = Builtins.filter(
          Convert.convert(
            installed_list,
            :from => "list",
            :to   => "list <string>"
          )
        ) { |item| item != nil }
      end
      deep_copy(installed_list)
    end

    #///////////////////////////////////////////////////////////////
    # Functions working with "cards"
    #///////////////////////////////////////////////////////////////

    # Get <B>index</B>th card.
    # @param [Fixnum] index Index of the card to get.
    # @return [Object] The 'index'th card or nil
    def CardGet(index)
      if index == nil || @cards == nil || Ops.less_than(index, 0) ||
          Ops.greater_or_equal(index, Builtins.size(@cards))
        return nil
      end
      Ops.get(@cards, index)
    end

    def CardGetUniq(uniq)
      return {} if uniq == nil || uniq == "" || Builtins.size(@cards) == 0

      ret = {}

      Builtins.foreach(
        Convert.convert(@cards, :from => "list", :to => "list <map>")
      ) do |card|
        ret = deep_copy(card) if Ops.get_string(card, "unique_key", "") == uniq
      end 


      deep_copy(ret)
    end

    # Add the <B>current_card</B> to the <B>cards</B>. Try to fill holes
    # after removes.
    # @return [Fixnum] Index of the added card.
    def CardAddCurrent
      @cards = [] if @cards == nil
      @current_card = {} if @current_card == nil
      index = nil

      # try to fill holes after a remove
      i = 0
      radio = Ops.get_boolean(@current_card, "radio", false)
      if radio && Ops.less_than(Builtins.size(@cards), 65)
        cards_s = Builtins.size(@cards)
        while Ops.less_than(cards_s, 65)
          @cards = Builtins.add(@cards, {})
          cards_s = Ops.add(cards_s, 1)
        end
      end
      @cards = Builtins.maplist(
        Convert.convert(
          @cards,
          :from => "list",
          :to   => "list <map <string, any>>"
        )
      ) do |card|
        if radio && Ops.less_than(i, 64)
          i = Ops.add(i, 1)
          next deep_copy(card)
        end
        if card == {} && index == nil
          index = i
          next deep_copy(@current_card)
        end
        i = Ops.add(i, 1)
        deep_copy(card)
      end
      if index == nil
        @cards = Builtins.add(@cards, @current_card)
        index = Ops.subtract(Builtins.size(@cards), 1)
      end
      @cards_dirty = true
      index
    end

    # Replace <B>index</B>th card with the <B>current_card</B>.
    # @param [Fixnum] index The index of the card to replace.
    # @return [Boolean] Returns true if successfully replaced.
    def CardReplaceWithCurrent(index)
      @cards = [] if @cards == nil
      success = false
      i = 0
      @cards = Builtins.maplist(
        Convert.convert(@cards, :from => "list", :to => "list <map>")
      ) do |card|
        if i == index
          card = deep_copy(@current_card)
          success = true
          @cards_dirty = true
        end
        i = Ops.add(i, 1)
        deep_copy(card)
      end
      success
    end

    # Remove <B>index</B>th card. Does not touch <B>current_card</B>.
    # (In fact, we just replace the card on the position of 'index' with nil.)
    # @param [Fixnum] index The index of the card to remove.
    # @return [Boolean] Returns true if the card was erased.
    def CardRemove(index)
      @cards = [] if @cards == nil
      success = false
      i = 0
      @cards = Builtins.maplist(
        Convert.convert(@cards, :from => "list", :to => "list <map>")
      ) do |card|
        if i == index && card != nil && card != {}
          @cards_to_del = Builtins.add(@cards_to_del, card)
          card = nil
          success = true
          @cards_dirty = true
        end
        i = Ops.add(i, 1)
        deep_copy(card)
      end
      success
    end

    # If the configuration was changed by the user, this will return true.
    # @return Has the configuration changed?
    def IsDirty
      @cards_dirty || @irc_modified || @stations_modified
    end

    # Creates a list of unique keys of cards that are already installed.
    # @return [Array] List of the unque keys.
    def CardsUniqueKeys
      @cards = [] if @cards == nil
      # unique keys of the already installed cards
      installed_uk = Builtins.maplist(
        Convert.convert(
          @cards,
          :from => "list",
          :to   => "list <map <string, any>>"
        )
      ) { |card| Ops.get(card, "unique_key") }

      # filter out nils
      Builtins.filter(
        Convert.convert(installed_uk, :from => "list", :to => "list <string>")
      ) { |item| item != nil }
    end

    # Return card index
    # @param [String] uniq Unique ID of the card
    # @return [Fixnum] index or nil if ID was not found
    def CardIndexUniqKey(uniq)
      ret = nil

      dvb_card_no = 0
      radio_card_no = 64
      tv_card_no = 0

      idx = 0
      Builtins.foreach(
        Convert.convert(@cards, :from => "list", :to => "list <map>")
      ) do |c|
        uniqkey = Ops.get_string(c, "unique_key")
        isdvb = Ops.get_boolean(c, "dvb", false)
        isradio = Ops.get_boolean(c, "radio", false)
        if uniqkey == nil
          uniqkey = isdvb ?
            Builtins.sformat("dvb.nouniqkey%1", dvb_card_no) :
            Builtins.sformat(
              "tv.nouniqkey%1",
              isradio ? radio_card_no : tv_card_no
            )
          Builtins.y2milestone("found empty uniq, using: %1", uniqkey)
        end
        ret = idx if uniq == uniqkey
        idx = Ops.add(idx, 1)
        if isdvb
          dvb_card_no = Ops.add(dvb_card_no, 1)
        else
          if isradio
            radio_card_no = Ops.add(radio_card_no, 1)
          else
            tv_card_no = Ops.add(tv_card_no, 1)
          end
        end
      end 


      ret
    end

    # Creates the content of the "configured card" Table in OverviewDialog()
    # @return [Array] List of `item()s
    def CardsAsItems
      @cards = [] if @cards == nil
      dvb_card_no = 0
      radio_card_no = 64
      tv_card_no = 0

      conf_list = Builtins.maplist(
        Convert.convert(
          @cards,
          :from => "list",
          :to   => "list <map <string, any>>"
        )
      ) do |card|
        ret = nil
        isdvb = Ops.get_boolean(card, "dvb", false)
        isradio = Ops.get_boolean(card, "radio", false)
        if card != nil && card != {}
          num = isdvb ? dvb_card_no : tv_card_no
          # suffix to differ between analog (TV) and digital (DVB) cards
          suff = isdvb ? _("DVB") : _("TV")

          uniq = Ops.get_string(
            card,
            "unique_key",
            isdvb ?
              Builtins.sformat("dvb.nouniqkey%1", dvb_card_no) :
              Builtins.sformat(
                "tv.nouniqkey%1",
                isradio ? radio_card_no : tv_card_no
              )
          )

          ret = Item(
            Id(uniq),
            Builtins.sformat("%1 - %2", num, suff),
            Ops.get_string(card, "name", "")
          )
        end
        if isdvb
          dvb_card_no = Ops.add(dvb_card_no, 1)
        else
          if isradio
            radio_card_no = Ops.add(radio_card_no, 1)
          else
            tv_card_no = Ops.add(tv_card_no, 1)
          end
        end
        deep_copy(ret)
      end

      Builtins.filter(
        Convert.convert(conf_list, :from => "list", :to => "list <term>")
      ) { |item| item != nil }
    end


    # Creates the content of the "configured card" Table in OverviewDialog()
    # @return [Array] List of `item()s
    def CardsAsItemMap
      @cards = [] if @cards == nil

      dvb_card_no = 0
      radio_card_no = 64
      tv_card_no = 0

      sound_cards = Convert.convert(
        Sound.GetSoundCardList,
        :from => "list",
        :to   => "list <map>"
      )
      Builtins.y2debug("sound_cards: %1", sound_cards)
      sndmap = Builtins.listmap(sound_cards) do |sndcard|
        {
          Ops.get_integer(sndcard, "card_no", -1) => Ops.get_string(
            sndcard,
            "name",
            ""
          )
        }
      end

      Builtins.y2milestone("cards: %1", @cards)

      conf_list = Builtins.maplist(
        Convert.convert(
          @cards,
          :from => "list",
          :to   => "list <map <string, any>>"
        )
      ) do |card|
        ret = {}
        isdvb = Ops.get_boolean(card, "dvb", false)
        isradio = Ops.get_boolean(card, "radio", false)
        if card != nil && card != {}
          num = isdvb ? dvb_card_no : tv_card_no
          # suffix to differ between analog (TV) and digital (DVB) cards
          suff = isdvb ? _("DVB") : _("TV")

          uniq = Ops.get_string(
            card,
            "unique_key",
            isdvb ?
              Builtins.sformat("dvb.nouniqkey%1", dvb_card_no) :
              Builtins.sformat(
                "tv.nouniqkey%1",
                isradio ? radio_card_no : tv_card_no
              )
          )

          Builtins.y2debug("card: %1", card)

          descr = []

          if num != nil && Ops.greater_or_equal(num, 0)
            # %1 is "TV" or "DVB", %2 is card number
            descr = Builtins.add(
              descr,
              Builtins.sformat(_("Configured as %1 card number %2"), suff, num)
            )
          end

          if Ops.get(card, "module") != nil
            descr = Builtins.add(
              descr,
              Builtins.sformat(
                _("Driver %1"),
                Builtins.mergestring(Ops.get_list(card, "module", []), ", ")
              )
            )
          end

          if Ops.get(card, "sound_card_no") != nil
            descr = Builtins.add(
              descr,
              Builtins.sformat(
                _("Attached to sound card '%1'"),
                Ops.get_string(
                  sndmap,
                  Ops.get_integer(card, "sound_card_no", -1),
                  ""
                )
              )
            )
          end

          # add firmware data if available
          if @firmware_database != nil &&
              Ops.greater_than(Builtins.size(@firmware_database), 0)
            if Ops.get(card, "fw_install") == false
              Builtins.y2milestone(
                "Card '%1' doesn't need a firmware",
                Ops.get_string(card, "name", "")
              )
            else
              Builtins.foreach(
                Convert.convert(
                  @firmware_database,
                  :from => "map",
                  :to   => "map <string, list <map <string, any>>>"
                )
              ) do |fwmod, fws|
                if Builtins.contains(Ops.get_list(card, "module", []), fwmod)
                  Builtins.foreach(fws) do |fw|
                    target = Ops.get_string(fw, "target", "")
                    source = Ops.get_string(fw, "source", "")
                    if target != "" && source != ""
                      inst = IsFWInstalled(Ops.add(@firmware_prefix, target))

                      descr = Builtins.add(
                        descr,
                        Ops.add(
                          _("Firmware: "),
                          inst ?
                            Builtins.sformat(_("Installed (%1)"), target) :
                            Builtins.sformat(
                              _("Not installed (%1 -> %2)"),
                              source,
                              target
                            )
                        )
                      )
                    end
                    # any required package?
                    required_packages = Ops.get_list(fw, "packages", [])
                    if Ops.greater_than(Builtins.size(required_packages), 0)
                      Builtins.y2milestone(
                        "Required packages for driver %1: %2",
                        fwmod,
                        required_packages
                      )
                    end
                    Builtins.foreach(required_packages) do |pkg|
                      # summary string, %1 is a package name, %2 is a status string: installed
                      descr = Builtins.add(
                        descr,
                        Builtins.sformat(
                          _("Package: %1 (%2)"),
                          # package status
                          pkg,
                          Package.Installed(pkg) ?
                            _("Installed") :
                            _("Not Installed")
                        )
                      )
                    end
                  end
                end
              end
            end
          end

          ret = {
            "id"          => uniq,
            "table_descr" => [
              Builtins.sformat("%1 - %2", num, suff),
              Ops.get_string(card, "name", "")
            ],
            "rich_descr"  => WizardHW.CreateRichTextDescription(
              Ops.get_string(card, "name", ""),
              descr
            )
          }
        end
        if isdvb
          dvb_card_no = Ops.add(dvb_card_no, 1)
        else
          if isradio
            radio_card_no = Ops.add(radio_card_no, 1)
          else
            tv_card_no = Ops.add(tv_card_no, 1)
          end
        end
        deep_copy(ret)
      end




      # add detected non-configured cards
      @detected_cards = [] if @detected_cards == nil

      # unique keys of the already installed cards
      installed_uk = CardsUniqueKeys()

      # create the list of `item()s (nil if it is already installed)
      detected_list = Builtins.maplist(
        Convert.convert(
          @detected_cards,
          :from => "list",
          :to   => "list <map <string, any>>"
        )
      ) do |card|
        uk = Ops.get_string(card, "unique_key")
        if uk != nil && !Builtins.contains(installed_uk, uk)
          uncofigured = {
            "id"          => uk,
            # status of the card, the text used in table, translation should be as short as possible
            "table_descr" => [
              _("Not configured"),
              Ops.get_string(card, "name", "")
            ],
            # status of the card - rich text
            "rich_descr"  => WizardHW.CreateRichTextDescription(
              Ops.get_string(card, "name", ""),
              WizardHW.UnconfiguredDevice
            )
          }

          conf_list = Builtins.add(conf_list, uncofigured)
        end
      end

      # remove empty items
      conf_list = Builtins.filter(conf_list) { |m| m != nil && m != {} }

      deep_copy(conf_list)
    end

    #///////////////////////////////////////////////////////////////
    # Functions working with "detected_cards"
    #///////////////////////////////////////////////////////////////

    # Get <B>index</B>th card.
    # @param [Fixnum] index Index of the card to get.
    # @return [Object] The 'index'th card or nil
    def DetectedCardGet(index)
      if Ops.less_than(index, 0) ||
          Ops.greater_or_equal(index, Builtins.size(@detected_cards))
        return {}
      end
      Ops.get_map(@detected_cards, index, {})
    end

    def DetectedCardUniqGet(uniq)
      return {} if uniq == nil || uniq == ""

      ret = {}

      Builtins.foreach(
        Convert.convert(@detected_cards, :from => "list", :to => "list <map>")
      ) do |card|
        ret = deep_copy(card) if Ops.get_string(card, "unique_key", "") == uniq
      end 


      deep_copy(ret)
    end

    def IndexDetectedCardUniqGet(uniq)
      if uniq == nil || uniq == "" || Builtins.size(@detected_cards) == 0
        return nil
      end

      index = 0
      ret = nil

      Builtins.foreach(
        Convert.convert(@detected_cards, :from => "list", :to => "list <map>")
      ) do |card|
        if Ops.get_string(card, "unique_key", "") == uniq
          ret = index
          index = Ops.add(index, 1)
        end
      end 


      ret
    end

    # List of the TV cards acceptable by the Selection Box widget in
    # the DetectedDialog(). The already installed cards are filtered out.
    # @return [Array] List of TV cards including Other (not detected) with `id(-1))
    def DetectedCardsAsItems
      @detected_cards = [] if @detected_cards == nil
      is_first = true

      # unique keys of the already installed cards
      installed_uk = CardsUniqueKeys()

      # create the list of `item()s (nil if it is already installed)
      card_no = 0
      detected_list = Builtins.maplist(
        Convert.convert(
          @detected_cards,
          :from => "list",
          :to   => "list <map <string, any>>"
        )
      ) do |card|
        ret = nil
        uk = Ops.get_string(card, "unique_key")
        if uk != nil && !Builtins.contains(installed_uk, uk)
          ret = Item(Id(card_no), Ops.get_string(card, "name", ""), is_first)
          is_first = false
        end
        card_no = Ops.add(card_no, 1)
        deep_copy(ret)
      end

      # filter out the nils
      detected_list = Builtins.filter(
        Convert.convert(detected_list, :from => "list", :to => "list <term>")
      ) { |card| card != nil }

      # For translators: Entry for manual selection in the list of the cards to configure
      Builtins.add(
        detected_list,
        Item(Id(-1), _("Other (not detected)"), is_first)
      )
    end

    #///////////////////////////////////////////////////////////////
    # Functions working with "cards_database"
    #///////////////////////////////////////////////////////////////

    # Grab the TV card from the database
    # @param [String] card_model model ID (to be set as "card=xx" module parameter)
    # @param [String] modname kernel module name (not necessary, used only to differene
    # the cards with same id)
    # @return card map
    def GetTvCard(card_model, modname)
      ret = {}
      Builtins.foreach(
        Convert.convert(@cards_database, :from => "list", :to => "list <map>")
      ) { |vendor| Builtins.foreach(Ops.get_list(vendor, "cards", [])) do |card|
        modnames = Ops.get_list(card, "module", [])
        if card_model == Ops.get_string(card, ["parameters", "card"], "") &&
            (ret == {} ||
              modname ==
                Ops.get(modnames, Ops.subtract(Builtins.size(modnames), 1), ""))
          ret = deep_copy(card)
        end
      end }
      deep_copy(ret)
    end

    # Create a list of items for the "Vendors:" SelectionBox in the
    # ManualDialog() screen.
    # @param [Hash] autodetected The autodetected card must be present in the database
    #                     so we add it if needed.
    # @param [Hash] parameters Parameters of card that should be preselected.
    # @param [String] mod Kernel module the reselected card uses
    # @return [Array] List of list of `item()s and number of the vendor to preselect
    def CardsDBVendorsAsItems(autodetected, parameters, mod)
      autodetected = deep_copy(autodetected)
      parameters = deep_copy(parameters)
      preselect_vendor = nil
      vendor_no = 0
      # Handle the autodetected card
      if autodetected != nil && autodetected != {}
        if Ops.get_string(parameters, "card", "-1") == "-1"
          preselect_vendor = vendor_no
        end
        vendor_no = Ops.add(vendor_no, 1)
      end

      vendors = Builtins.maplist(
        Convert.convert(@cards_database, :from => "list", :to => "list <map>")
      ) do |vendor|
        if preselect_vendor == nil
          Builtins.foreach(Ops.get_list(vendor, "cards", [])) do |card|
            mods = Ops.get_list(card, "module", [])
            if preselect_vendor == nil &&
                (mod == nil ||
                  mod == Ops.get(mods, Ops.subtract(Builtins.size(mods), 1), "")) &&
                CmpParameters(Ops.get_map(card, "parameters", {}), parameters)
              preselect_vendor = vendor_no
            end
          end
        end
        ret = Item(
          Id(vendor_no),
          Ops.get_string(vendor, "name", ""),
          preselect_vendor == vendor_no
        )
        vendor_no = Ops.add(vendor_no, 1)
        deep_copy(ret)
      end

      if autodetected != nil && autodetected != {}
        # Item of cards list:
        vendors = Builtins.prepend(
          vendors,
          Item(Id(0), _("Autodetected card"), preselect_vendor == 0)
        )
      end
      [vendors, preselect_vendor]
    end

    # Create a list of cards of the selected vendor.
    # @param [Hash] autodetected The autodetected card must be present in the database
    #                     so we add it if needed.
    # @param [Fixnum] sel_vendor The number of the selected vendor.
    # @return [Array] List of cards of the selected vendor.
    def CardsDBVendorGetCards(autodetected, sel_vendor)
      autodetected = deep_copy(autodetected)
      return [] if sel_vendor == nil || Ops.less_than(sel_vendor, 0)

      if autodetected != nil && autodetected != {}
        if sel_vendor == 0
          return [autodetected]
        else
          return Ops.get_list(
            @cards_database,
            [Ops.subtract(sel_vendor, 1), "cards"],
            []
          )
        end
      else
        return Ops.get_list(@cards_database, [sel_vendor, "cards"], [])
      end
    end

    #///////////////////////////////////////////////////////////////
    # Functions working with "tuners_database"
    #///////////////////////////////////////////////////////////////

    # Returns the tuner map according to its ID
    # @param [String] kernel_name Name of the main module for this card.
    # @param [String] tuner_id ID of selected tuner
    # @return [Hash] Tuner
    def GetTuner(kernel_name, tuner_id)
      Ops.get_map(@tuners_by_id, [kernel_name, tuner_id], {})
    end


    # Are there any tuners for the <B>kernel_module</B>?
    # @param [String] kernel_module Name of the main module for this card.
    # @return [Boolean] Are there available tuners for it?
    def TunersDBHasTunersFor(kernel_module)
      return false if kernel_module == nil

      Builtins.haskey(@tuners_database, kernel_module)
    end

    # List of tuners for TV cards acceptable by the SelectionBox widget.
    # @param [String] kernel_module The module for which do we need the list.
    # @param [Hash] selected_tuner The previously selected tuner.
    # @return [Array] List of `item()s.
    def TunersDBAsItems(kernel_module, selected_tuner)
      selected_tuner = deep_copy(selected_tuner)
      return [] if @tuners_database == nil
      tuners = Ops.get_list(@tuners_database, kernel_module, [])
      tuners = Builtins.prepend(
        tuners,
        {
          # Default item of tuners list:
          "name"       => _("Default (detected)"),
          "parameters" => { "tuner" => "-1" }
        }
      )

      if selected_tuner == nil || selected_tuner == {}
        selected_tuner = { "parameters" => { "tuner" => "-1" } }
      end
      tuner_no = 0
      some_is_selected = false
      selected_tuner_parameters = Ops.get_map(selected_tuner, "parameters", {})
      Builtins.maplist(
        Convert.convert(
          tuners,
          :from => "list",
          :to   => "list <map <string, any>>"
        )
      ) do |tuner|
        select_this = CmpParameters(
          Ops.get_map(tuner, "parameters", {}),
          selected_tuner_parameters
        )
        ret = Item(
          Id(tuner_no),
          Ops.get_string(tuner, "name", ""),
          select_this && !some_is_selected
        )
        tuner_no = Ops.add(tuner_no, 1)
        some_is_selected = true if select_this
        deep_copy(ret)
      end
    end

    # Return the <B>number</B>th tuner.
    # @param [String] kernel_module The module for which do we need the list.
    # @param [Fixnum] number The number of the tuner to be selected.
    # @return [Hash] Tuner.
    def TunersDBSelectTuner(kernel_module, number)
      tuners = Ops.get_list(@tuners_database, kernel_module, [])
      tuners = Builtins.prepend(
        tuners,
        {
          # Default item of tuners list:
          "name"       => _("Default (detected)"),
          "parameters" => { "tuner" => "-1" }
        }
      )
      @cards_dirty = true
      Ops.get_map(tuners, number, {})
    end

    #///////////////////////////////////////////////////////////////
    # Functions working with "kernel_modules"
    #///////////////////////////////////////////////////////////////


    # List of the kernel modules for radio cards acceptable by the Combo Box
    # widget in the ManualDetailsDialog().
    # @param [String] selected_module The module which should be selected in the widget
    # @return [Array] List of `item()s
    def ModulesAsItems(modules, selected_module)
      modules = deep_copy(modules)
      Builtins.maplist(
        Convert.convert(modules, :from => "map", :to => "map <string, map>")
      ) do |key, value|
        name = key
        desc = Ops.get_string(value, "module_description", "")
        if desc != "" && desc != "<none>"
          name = Builtins.sformat("%1: %2", key, desc)
        end
        Item(Id(key), name, key == selected_module)
      end
    end


    # List of the parameters for the selected kernel module acceptable by
    # the Table widget in the ManualDetailsDialog().
    # @param [String] selected_module The module which is selected in the Combo Box.
    # @param [Hash] parameters The current values of the kernel module parameters.
    # @return [Array] List of `item()s.
    def ModuleParametersAsItems(modules, selected_module, parameters)
      modules = deep_copy(modules)
      parameters = deep_copy(parameters)
      kernel_module = Ops.get_map(modules, selected_module, {})
      return [] if kernel_module == nil

      param_list = Builtins.maplist(
        Convert.convert(
          kernel_module,
          :from => "map",
          :to   => "map <string, any>"
        )
      ) do |key, value|
        result = nil
        if Builtins.substring(key, 0, 7) != "module_"
          result = Item(
            Id(key),
            key,
            Ops.get_string(parameters, key, ""),
            value
          )
        end
        deep_copy(result)
      end

      # filter out nils
      Builtins.filter(
        Convert.convert(param_list, :from => "list", :to => "list <term>")
      ) { |val| val != nil }
    end
    #/////////////////////////////////////////////////////////////////////////
    #-------------------------------------------------- LIRC related functions

    # Read IRC settings
    # @return Symbol for next or abort dialog.
    def ReadIRC
      if !Package.InstalledAll(["lirc", "lirc-remotes"])
        Builtins.y2warning(
          "lirc and lirc-remotes are missing, not reading LIRC config"
        )
        return :next
      end

      @lirc_installed = true

      @cards_with_ir_kbd_gpio = Convert.to_map(
        SCR.Read(path(".target.yast2"), "tv_cards-lirc_gpio.ycp")
      )

      @use_irc = Service.Info("lirc") != {} ?
        Service.Status("lirc") == 0 :
        false

      @irc_module = Ops.greater_or_equal(
        SCR.Read(path(".target.size"), "/etc/sysconfig/lirc"),
        0
      ) ?
        Convert.to_string(SCR.Read(path(".sysconfig.lirc.LIRC_MODULE"))) :
        ""
      @irc_module = "" if @irc_module == nil

      if FileUtils.Exists("/etc/lircd.conf")
        @irc_config = "/etc/lircd.conf"
      else
        @irc_config = "/usr/share/lirc/remotes/devinput/lircd.conf.devinput"

        if !FileUtils.Exists(@irc_config)
          # error message, %1 is a file name
          Report.Error(
            Builtins.sformat(
              _("File %1 is missing,\ncheck your installation."),
              @irc_config
            )
          )
        end
      end

      if Ops.greater_or_equal(
          SCR.Read(path(".target.size"), "/usr/share/lirc"),
          0
        )
        out = Convert.to_map(
          SCR.Execute(
            path(".target.bash_output"),
            "/usr/bin/find  /usr/share/lirc/remotes/ -name *lircd*"
          )
        )
        @remotes = Builtins.sort(
          Builtins.splitstring(Ops.get_string(out, "stdout", ""), "\n")
        ) 
        # FIXME choose from remotes
      else
        @remotes = []
      end

      :next
    end

    # Write IRC settings
    # @return Symbol for next or abort dialog.
    def WriteIRC
      if !@lirc_installed
        Builtins.y2warning("lirc is not installed, not writing lirc config")
        return :next
      end

      if Ops.greater_or_equal(
          SCR.Read(path(".target.size"), "/etc/sysconfig/lirc"),
          0
        )
        # write sysconfig values
        SCR.Write(path(".sysconfig.lirc.LIRC_MODULE"), @irc_module)
        SCR.Write(path(".sysconfig.lirc"), nil)
      else
        Builtins.y2warning(
          "/etc/syconfig/lirc doesn't exist, writing the configuration has been skipped"
        )
      end

      Builtins.y2milestone("config file: %1", @irc_config)

      if @use_irc
        # 2. lircd config
        # ... copy config file to /etc/lircd.conf
        if SCR.Read(path(".target.size"), "/etc/lircd.conf") != -1
          SCR.Execute(
            path(".target.bash"),
            "/bin/cp /etc/lircd.conf /etc/lircd.conf.YaST2save"
          )
        end
        if @irc_config != "/etc/lircd.conf" &&
            SCR.Read(path(".target.size"), @irc_config) != -1
          SCR.Execute(
            path(".target.bash"),
            Builtins.sformat("/bin/cp %1 /etc/lircd.conf", @irc_config)
          )
          Builtins.y2milestone(
            "config file: %1 copied to /etc/lircd.conf",
            @irc_config
          )
        end

        # does the service exist?
        if Service.Info("lirc") != {}
          # adjust runlevels:
          Service.Adjust("lirc", "enable")
          # start the service
          if Service.Status("lirc") == 0
            Service.RunInitScript("lirc", "restart")
          else
            Service.RunInitScript("lirc", "start")
          end
        else
          Builtins.y2error("Service 'lirc' doesn't exist!")
        end
      else
        if Service.Info("lirc") != {}
          # adjust runlevels:
          Service.Adjust("lirc", "disable")
          # stop the service
          Service.RunInitScript("lirc", "stop")
        end
      end
      :next
    end

    # Load the desription of irc kernel modules (modinfo)
    def LoadIRCModulesDescription
      ir_desc = {
        # description for ir-kbd-gpio module
        "ir-kbd-gpio" => _(
          "Input driver for bt8x8 gpio IR remote controls"
        ),
        # description for ir-kbd-i2c module
        "ir-kbd-i2c"  => _(
          "Input driver for i2c IR remote controls"
        )
      }

      @irc_modules = Builtins.listmap(
        Convert.convert(
          @irc_modules_list,
          :from => "list",
          :to   => "list <string>"
        )
      ) do |mod|
        if Ops.get_string(ir_desc, mod, "") != ""
          next { mod => Ops.get_string(ir_desc, mod, "") }
        end
        modinfo = Convert.to_map(
          SCR.Read(Builtins.add(path(".modinfo.kernel.misc"), mod))
        )
        { mod => Ops.get_string(modinfo, "module_description", "") }
      end

      nil
    end

    # Decides which LIRC module can be used accoring to current TV card
    # @return module name
    def GetIRCModule
      ret = "ir-kbd-i2c"

      card = deep_copy(@current_card)
      card = Convert.to_map(CardGet(0)) if card == {}
      return ret if card == nil && @detected_cards == []

      cardnr = Builtins.tointeger(
        Ops.get_string(card, ["parameters", "card"], "-1")
      )
      if cardnr == -1
        # autodetected
        card_id = -1
        card = Ops.get_map(@detected_cards, 0, {}) if card == nil
        # find the ID of current card (saved in detected_cards list)
        Builtins.foreach(
          Convert.convert(
            @detected_cards,
            :from => "list",
            :to   => "list <map <string, any>>"
          )
        ) do |det_card|
          if Ops.get(card, "module") == Ops.get_list(det_card, "module", []) &&
              Ops.get(card, "name") == Ops.get_string(det_card, "name", "")
            card_id = Ops.get_integer(det_card, "card_id", -1)
          end
        end
        ret = "ir-kbd-gpio" if Builtins.contains(@card_ids_ir_kbd_gpio, card_id)
      else
        # manualy set card
        mods = Ops.get_list(card, "module", [])
        mod = Ops.get(mods, Ops.subtract(Builtins.size(mods), 1), "bttv")
        if Builtins.contains(
            Ops.get_list(@cards_with_ir_kbd_gpio, mod, []),
            cardnr
          )
          ret = "ir-kbd-gpio"
        end
      end
      ret
    end

    #/////////////////////////////////////////////////////////////////////////
    #------------------------------------------- TV stations related functions

    # Read the whole contents of xawtvrc file and return it as a map
    # @param path proper agent (handling either global or temporary config file)
    # return map
    def ReadStationsConfig(pth)
      xawtvrc = {}
      Builtins.foreach(SCR.Dir(Builtins.add(pth, "s"))) do |section|
        xawtvrc = Builtins.add(xawtvrc, section, {})
        Builtins.foreach(SCR.Dir(Builtins.add(Builtins.add(pth, "v"), section))) do |attr|
          Ops.set(
            xawtvrc,
            [section, attr],
            SCR.Read(
              Builtins.add(Builtins.add(Builtins.add(pth, "v"), section), attr)
            )
          )
        end
      end
      deep_copy(xawtvrc)
    end

    # Write to /etc/X11/xawtvrc
    def WriteStationsConfig
      # create a backup
      if SCR.Read(path(".target.size"), "/etc/X11/xawtv") != -1
        SCR.Execute(
          path(".target.bash"),
          "/bin/cp /etc/X11/xawtvrc /etc/X11/xawtvrc.YaSTsave"
        )
      else
        SCR.Execute(path(".target.bash"), "/bin/touch /etc/X11/xawtvrc")
      end

      new_sections = []
      Builtins.foreach(
        Convert.convert(
          @channels_config,
          :from => "map",
          :to   => "map <string, map <string, string>>"
        )
      ) do |sec_name, section|
        new_sections = Builtins.add(new_sections, sec_name)
        Builtins.foreach(section) do |key, value|
          SCR.Write(
            Builtins.add(Builtins.add(path(".xawtvrc.v"), sec_name), key),
            value
          )
        end
      end
      # remove removed stations
      Builtins.foreach(SCR.Dir(path(".xawtvrc.s"))) do |section|
        if !Builtins.contains(new_sections, section)
          SCR.Write(Builtins.add(path(".xawtvrc.s"), section), nil)
        end
      end
      true
    end


    # Load the modules for TV suport now, use current (not yet saved) options
    # It calls something like 'modprobe -C /dev/null bttv card=2 tuner=23'
    # @return empty string on success, error message otherwise
    def tv_tmp_start
      modnames = Ops.get_list(@current_card, "module", [])
      ret = ""

      Builtins.foreach(modnames) do |modname|
        params = ""
        Builtins.maplist(
          Ops.get_map(@current_card, ["parameters", modname], {})
        ) { |k, v| params = Ops.add(params, Builtins.sformat(" %1=%2", k, v)) }
        # we need to tell 'modprobe' not to look into modprobe.conf now, because
        # it may contain messed options for the module %1 that will break the
        # module loading. (modprobe would merge options specified in param %2 with
        # those specified in modprobe.conf)
        cmd = Builtins.sformat(
          "/sbin/modprobe -C /dev/null %1 %2",
          modname,
          params
        )
        Builtins.y2milestone("command to run: %1", cmd)
        res = Convert.to_map(SCR.Execute(path(".target.bash_output"), cmd, {}))
        Builtins.y2milestone("modprobe output: %1", res)
        if Ops.get_string(res, "stderr", "") != ""
          ret = Ops.add(Ops.add(ret, "\n"), Ops.get_string(res, "stderr", ""))
        end
      end

      ret
    end

    # Initialize stations configuration (read global config etc.)
    def InitializeStationsConfig
      agent_file = Builtins.sformat("%1/tmp_xawtvrc.scr", @tmpdir)
      # create new agent for reading temporary xawtvrc
      SCR.Write(
        path(".target.string"),
        agent_file,
        Builtins.sformat(
          ".tmp.xawtvrc\n" +
            "\n" +
            "`ag_ini(\n" +
            "  `IniAgent(\n" +
            "    \"%1/xawtvrc\",\n" +
            "    $[\n" +
            "      \"comments\": [ \"^[ \\t]*#.*\", \"#.*\", \"^[ \\t]*$\" ],\n" +
            "      \"sections\" : [\n" +
            "        $[\n" +
            "        \"begin\" : [ \"^[ \\t]*\\[[ \\t]*(.*[^ \\t])[ \\t]*\\][ \\t]*\", \"[%%s]\"],\n" +
            "        ],\n" +
            "      ],\n" +
            "      \"params\" : [\n" +
            "        $[\n" +
            "        \"match\" : [ \"^[ \\t]*([^=]*[^ \\t=])[ \\t]*=[ \\t]*(.*[^ \\t]|)[ \\t]*$\",\n" +
            "\t\t    \"%%s = %%s\"],\n" +
            "\t],\n" +
            "      ],\n" +
            "    ]\n" +
            "  )\n" +
            ")",
          @tmpdir
        )
      )
      SCR.RegisterAgent(path(".tmp.xawtvrc"), agent_file)

      # read global configuration file
      if SCR.Read(path(".target.size"), "/etc/X11/xawtvrc") != -1
        @channels_config = ReadStationsConfig(path(".xawtvrc"))
      end
      if !Builtins.haskey(@channels_config, "defaults")
        @channels_config = Builtins.add(@channels_config, "defaults", {})
      end
      if !Builtins.haskey(@channels_config, "global")
        @channels_config = Builtins.add(@channels_config, "global", {})
      end
      true
    end

    # Read all TV card settings from the SCR
    # @param [Proc] abort A block that can be called by Read to find
    #	      out whether abort is requested. Returns true if abort
    #	      was pressed.
    # @return [Boolean] True on success
    def Read(abort)
      abort = deep_copy(abort)
      read_aborted = false

      # Title of initialization dialog
      caption = _("Initializing TV and Radio Card Configuration")
      return false if !ReadCardsDatabase()

      return false if !ReadTunersDatabase()

      return false if !ReadSettings()

      return false if !Detect()

      ReadIRC()
      @tmpdir = Convert.to_string(SCR.Read(path(".target.tmpdir")))

      InitializeStationsConfig()

      Builtins.y2milestone("All cards (read & detected): %1", @cards)

      true
    end

    # Update the SCR according to tv settings
    # @param [Proc] abort A block that can be called by Write to find
    #	      out whether abort is requested. Returns true if abort
    #	      was pressed.
    # @return [Boolean] True on success
    def Write(abort)
      abort = deep_copy(abort)
      return true if !IsDirty()

      write_aborted = false
      # For translators: Title of the "save" dialog
      caption = _("Saving TV and Radio Card Configuration")
      # Set the right number of stages
      #   1: Write the settings
      #   2: Write the sound volume
      #   3: Install necessary software
      no_of_steps = 3

      stages = [
        # Progress stage
        _("Install firmware"),
        # Progress stage
        _("Write the settings"),
        # Progress stage
        _("Update sound volume")
      ]

      steps = [
        # Progress step
        _("Installing firmware..."),
        # Progress step
        _("Writing the settings..."),
        # Progress step
        _("Updating the sound volume...")
      ]

      if !@not_ask
        # Progress stage
        stages = Builtins.add(stages, _("Check for TV and radio applications"))
        # Progress step
        steps = Builtins.add(
          steps,
          _("Checking for TV and radio applications...")
        )
        no_of_steps = Ops.add(no_of_steps, 1)
      end
      # Progress stage
      stages = Builtins.add(stages, _("Write IRC settings"))

      # Progress step
      steps = Builtins.add(steps, _("Writing IRC settings..."))

      # Progress stage
      stages = Builtins.add(stages, _("Write TV stations"))

      # Progress step
      steps = Builtins.add(steps, _("Writing TV stations..."))

      # Progress step
      steps = Builtins.add(steps, _("Finished"))

      Progress.New(caption, " ", no_of_steps, stages, steps, "")

      # no "eval (abort)" is currently called. May need
      # improvement when the writing sequence gets longer.

      Builtins.y2debug("cards: %1", @cards)

      # Install firmware
      Progress.NextStage

      return false if @cards_dirty && !InstallFW()

      Progress.NextStage

      # install required kernel packages
      kernelmodules = RequiredModules(true)

      if Ops.greater_than(Builtins.size(kernelmodules), 0)
        Package.InstallKernel(kernelmodules)
      end

      # Write the settings
      return false if @cards_dirty && !WriteSettings()

      # Write the sound volume
      Progress.NextStage
      return false if @cards_dirty && !WriteSoundVolume()

      # check for applications for TV view/radio listen
      if !@not_ask
        Progress.NextStage

        # don't install the applications in a minimal system (text mode),
        # the applications have many dependencies (X11,...)
        if Package.Installed("xorg-x11-libs")
          # do we have TV or radio card?
          i = 0
          tv = false
          radio = false
          while Ops.less_than(i, Builtins.size(@cards))
            if Ops.get(@cards, i) != nil
              if Ops.less_than(i, 64)
                tv = true
              else
                radio = true
              end
            end
            i = Ops.add(i, 1)
          end

          Builtins.y2milestone(
            "Detected TV card: %1, Radio card: %2",
            tv,
            radio
          )

          apps = []
          kde = Package.Installed("kdelibs3") || Package.Installed("kdelibs4")

          if tv
            if Package.Installed("gnome-panel")
              @tv_app = "motv"
            elsif kde
              @tv_app = "kdetv"
            end

            if !Package.Installed(@tv_app) && Package.Available(@tv_app) == true
              apps = Builtins.add(apps, @tv_app)
            end

            if !Package.Installed("alevt") && Package.Available("alevt") == true
              apps = Builtins.add(apps, "alevt")
            end

            if !Package.Installed("nxtvepg") &&
                Package.Available("nxtvepg") == true
              apps = Builtins.add(apps, "nxtvepg")
            end

            Builtins.y2milestone("TV packages to install: %1", apps)
          end

          if radio && kde && !Package.Installed("kradio") &&
              Package.Available("kradio") == true
            Builtins.y2milestone("Adding kradio to the package list")
            apps = Builtins.add(apps, "kradio")
          end

          Builtins.y2milestone("Packages to install: %1", apps)

          # installing radio and TV applications
          if Builtins.contains(apps, "kradio") &&
              Ops.greater_than(Builtins.size(apps), 1)
            # Popup text (required application are %1):
            InstallApplication(
              apps,
              Builtins.sformat(
                _(
                  "<p>To enable you to watch TV and listen to radio on your computer,<br>\n" +
                    "these packages should be installed:<br>\n" +
                    "<b>%1</b><br>\n" +
                    "Install them now?\n" +
                    "</p>\n"
                ),
                Builtins.mergestring(apps, ", ")
              )
            )
          # installing only TV applications
          elsif !Builtins.contains(apps, "kradio") &&
              Ops.greater_than(Builtins.size(apps), 0)
            # Popup text (required application are %1):
            InstallApplication(
              apps,
              Builtins.sformat(
                _(
                  "<p>To enable you to watch TV on your computer,<br>\n" +
                    "these packages should be installed:<br>\n" +
                    "<b>%1</b><br>\n" +
                    "Install them now?\n" +
                    "</p>\n"
                ),
                Builtins.mergestring(apps, ", ")
              )
            )
          # installing only radio application
          elsif apps == ["kradio"]
            # Popup text (required application is %1):
            InstallApplication(
              ["kradio"],
              Builtins.sformat(
                _(
                  "<p>To listen to radio on your computer, you can use the <b>%1</b> application.\nInstall it now?</p>"
                ),
                "kradio"
              )
            )
          end
        else
          Builtins.y2milestone(
            "X11 libraries (xorg-x11-libs) are not installed, skipping installation of TV packages."
          )
        end

        # save not_ask status
        SCR.Write(
          path(".target.ycp"),
          Ops.add(Directory.vardir, "/tv.ycp"),
          { "dont_ask_for_application" => @not_ask }
        )
      end

      WriteIRC() if @irc_modified

      WriteStationsConfig() if @stations_modified

      # increase the progress to "finish"
      Progress.NextStage

      true
    end

    # Get all TV settings from the first parameter
    # (For use by autoinstallation.)
    # @param [Hash] settings The YCP structure to be imported.
    # @return [Boolean] True on success
    def Import(settings)
      settings = deep_copy(settings)
      settings = {} if settings == nil

      @cards = Ops.get_list(settings, "cards", [])
      true
    end

    # Dump the tv settings to a single map
    # (For use by autoinstallation.)
    # @return [Hash] Dumped settings (later acceptable by Import ())
    def Export
      # All the data is stored in the "cards" variable
      { "cards" => @cards }
    end

    # Create a configuration automagically.
    def Propose
      # unique keys of the already installed cards
      installed_uk = CardsUniqueKeys()

      any_tv_configured = false

      # add the not yet configured cards
      Builtins.foreach(
        Convert.convert(
          @detected_cards,
          :from => "list",
          :to   => "list <map <string, any>>"
        )
      ) do |card|
        uk = Ops.get_string(card, "unique_key")
        cardmodules = Ops.get_list(card, "module", [])
        # check whether the card can be automatically configured
        # do not autoconfigure blacklisted cards
        if uk != nil && !Builtins.contains(installed_uk, uk) &&
            cardmodules != nil &&
            Ops.greater_than(Builtins.size(cardmodules), 0) &&
            !(Ops.get_boolean(card, "dvb", false) &&
              Ops.get_boolean(card, "unknown", false)) &&
            !IsCardBlacklisted(card)
          @current_card = deep_copy(card)
          @current_card_no = nil

          # add the card
          CardAddCurrent()
          Builtins.y2milestone("Autoconfigured card: %1", card)

          any_tv_configured = true
        end
      end

      # setup the sound volume
      if any_tv_configured
        Builtins.foreach(
          Convert.convert(
            Sound.GetSoundCardList,
            :from => "list",
            :to   => "list <map <string, any>>"
          )
        ) do |card|
          sound_card_no = Ops.get_integer(card, "card_no", -2)
          if sound_card_no != -2
            Sound.SetVolume(sound_card_no, "Line", 80)
            Sound.SetVolume(sound_card_no, "Video", 80)
          end
        end
        SaveVolume()
      end

      nil
    end

    # Build a textual summary that can be used e.g. in inst_hw_config () or
    # something similar.
    # @return [String] Summary of the configuration.
    def Summary
      # The already configured tv cards
      installed_list = InstalledCardsSummary()

      # list of the unique keys of the already installed cards
      installed_uk = Builtins.add(
        Builtins.maplist(
          Convert.convert(
            @cards,
            :from => "list",
            :to   => "list <map <string, any>>"
          )
        ) { |card| Ops.get(card, "unique_key") },
        "none"
      )

      # list of the not configured tv cards
      detected_list = []
      Builtins.foreach(
        Convert.convert(
          @detected_cards,
          :from => "list",
          :to   => "list <map <string, any>>"
        )
      ) do |card|
        if !Builtins.contains(
            installed_uk,
            Ops.get_string(card, "unique_key", "none")
          )
          # blacklist info details
          blacklist_reasons = []

          if AnyDriverBlacklisted(Ops.get_list(card, "modules", []))
            # automatic configuration skipped - details
            blacklist_reasons = Builtins.add(
              blacklist_reasons,
              Builtins.sformat(_("the driver is disabled"))
            )
          end

          if IsModaliasBlacklisted(Ops.get_string(card, "modalias", ""))
            # automatic configuration skipped - details
            blacklist_reasons = Builtins.add(
              blacklist_reasons,
              Builtins.sformat(_("the card is disabled"))
            )
          end

          summary_line = Summary.Device(
            Ops.get_string(card, "name", ""),
            Ops.greater_than(Builtins.size(blacklist_reasons), 0) ?
              # summary line in the HW proposal, %1 - details why it cannot be autoconfigured
              Builtins.sformat(
                _("Automatic configuration skipped (%1)"),
                Builtins.mergestring(blacklist_reasons, ", ")
              ) :
              Summary.NotConfigured
          )

          detected_list = Builtins.add(detected_list, summary_line)
        end
      end
      Summary.DevicesList(
        Convert.convert(
          Builtins.union(detected_list, installed_list),
          :from => "list",
          :to   => "list <string>"
        )
      )
    end

    publish :variable => :cards, :type => "list", :private => true
    publish :variable => :cards_to_del, :type => "list", :private => true
    publish :variable => :cards_dirty, :type => "boolean", :private => true
    publish :variable => :current_card, :type => "map"
    publish :variable => :current_card_no, :type => "integer"
    publish :variable => :detected_cards, :type => "list", :private => true
    publish :variable => :cards_database, :type => "list"
    publish :variable => :dvb_cards_database, :type => "list"
    publish :variable => :firmware_database, :type => "map"
    publish :variable => :tuners_database, :type => "map", :private => true
    publish :variable => :tuners_by_id, :type => "map", :private => true
    publish :variable => :kernel_modules, :type => "map"
    publish :variable => :radio_modules, :type => "map"
    publish :variable => :dvb_modules, :type => "map"
    publish :variable => :dvb_core_drivers, :type => "map"
    publish :variable => :proposal_valid, :type => "boolean"
    publish :variable => :not_ask, :type => "boolean"
    publish :variable => :tv_app, :type => "string", :private => true
    publish :variable => :tmpdir, :type => "string"
    publish :variable => :used_modprobe_conf, :type => "boolean"
    publish :variable => :stations_modified, :type => "boolean"
    publish :variable => :channels_config, :type => "map"
    publish :variable => :irc_module, :type => "string"
    publish :variable => :irc_config, :type => "string"
    publish :variable => :use_irc, :type => "boolean"
    publish :variable => :irc_modified, :type => "boolean"
    publish :variable => :irc_modules_list, :type => "list"
    publish :variable => :irc_modules, :type => "map"
    publish :variable => :remotes, :type => "list"
    publish :variable => :cards_with_ir_kbd_gpio, :type => "map", :private => true
    publish :variable => :card_ids_ir_kbd_gpio, :type => "list", :private => true
    publish :variable => :firmware_prefix, :type => "string", :private => true
    publish :variable => :fw_source_cache, :type => "map <string, string>", :private => true
    publish :variable => :blacklisted_aliases, :type => "list <string>", :private => true
    publish :variable => :blacklisted_modules, :type => "list <string>", :private => true
    publish :variable => :confirm_packages, :type => "boolean", :private => true
    publish :variable => :lirc_installed, :type => "boolean"
    publish :function => :IsDirty, :type => "boolean ()"
    publish :function => :CmpParameters, :type => "boolean (map, map)", :private => true
    publish :function => :SoundCardsAsItems, :type => "list ()", :private => true
    publish :function => :tvUserInput, :type => "any ()", :private => true
    publish :function => :ErrorWithDetails, :type => "void (string, string)", :private => true
    publish :variable => :no_tuner, :type => "string", :private => true
    publish :variable => :other_vendors, :type => "string", :private => true
    publish :variable => :unknown_bttv_card, :type => "string", :private => true
    publish :variable => :unknown_cx88xx_card, :type => "string", :private => true
    publish :variable => :unknown_saa7134_card, :type => "string", :private => true
    publish :variable => :all_card_names, :type => "list <string>", :private => true
    publish :variable => :all_module_items, :type => "list", :private => true
    publish :function => :detect_cdrom, :type => "list <map> ()", :private => true
    publish :function => :CDpopup, :type => "map (string, string, list <map>)", :private => true
    publish :function => :mount_device, :type => "string (string)", :private => true
    publish :function => :umount_device, :type => "boolean (string)", :private => true
    publish :function => :get_card_names, :type => "list <string> (string, string)", :private => true
    publish :function => :get_running_cards, :type => "list ()", :private => true
    publish :function => :get_module_params, :type => "map (string)", :private => true
    publish :function => :add_alias, :type => "map (map, integer)", :private => true
    publish :function => :add_common_options, :type => "map (map, integer)", :private => true
    publish :function => :alsa_oss, :type => "list (integer)", :private => true
    publish :function => :get_module_names, :type => "list ()", :private => true
    publish :function => :get_vol_settings, :type => "list <list <list>> ()", :private => true
    publish :function => :set_vol_settings, :type => "boolean (list)", :private => true
    publish :function => :hardware_name, :type => "string (map)", :private => true
    publish :function => :filter_configured, :type => "list <map> (list <map>, list <map>)", :private => true
    publish :function => :get_card_label, :type => "string (map)", :private => true
    publish :function => :is_snd_alias, :type => "boolean (string)", :private => true
    publish :function => :isa_uniq, :type => "string ()", :private => true
    publish :function => :read_rc_vars, :type => "map ()", :private => true
    publish :function => :SaveUniqueKeys, :type => "boolean (list, list)", :private => true
    publish :function => :search_card_id, :type => "integer (string)", :private => true
    publish :function => :itemize_list, :type => "list (list, integer)", :private => true
    publish :function => :nm256hack, :type => "boolean (string)", :private => true
    publish :function => :layout_id, :type => "boolean ()", :private => true
    publish :function => :get_module, :type => "map (map)", :private => true
    publish :function => :unmute, :type => "void (list, integer)", :private => true
    publish :function => :check_module, :type => "string (map, integer)", :private => true
    publish :function => :restore_mod_params, :type => "map (map, map)", :private => true
    publish :function => :FontsInstalled, :type => "boolean ()", :private => true
    publish :function => :HasFonts, :type => "boolean (map)", :private => true
    publish :function => :InstallFonts, :type => "void (string, boolean)", :private => true
    publish :function => :need_nm256_opl3sa2_warn, :type => "boolean (list)", :private => true
    publish :function => :nm256_opl3sa2_warn, :type => "void (list)", :private => true
    publish :function => :Thinkpad600E_cs4236_hack, :type => "void (integer)", :private => true
    publish :function => :recalc_save_entries, :type => "list <map> (list <map>)", :private => true
    publish :function => :createAliasComment, :type => "string (string, string)", :private => true
    publish :function => :tounprefixedhexstring, :type => "string (integer)", :private => true
    publish :function => :SaveOneModulesEntry, :type => "boolean (map)", :private => true
    publish :function => :WriteSlotsOption, :type => "void (map <integer, string>)", :private => true
    publish :function => :RemovedUnusuedModulesFromSysconfig, :type => "void ()", :private => true
    publish :function => :SaveModulesOptions, :type => "void (list)", :private => true
    publish :function => :removeOldEntries, :type => "void (list)", :private => true
    publish :function => :RemoveOldConfiguration, :type => "void ()", :private => true
    publish :function => :RemoveHWConfig, :type => "boolean ()", :private => true
    publish :function => :SaveModulesEntry, :type => "map (list, list)", :private => true
    publish :function => :SaveVolume, :type => "boolean ()", :private => true
    publish :function => :SaveRCValues, :type => "string (map)", :private => true
    publish :function => :SetConfirmPackages, :type => "void (boolean)"
    publish :function => :ConfirmPackages, :type => "boolean ()"
    publish :function => :InstallApplication, :type => "void (list <string>, string)", :private => true
    publish :function => :ReadUserSettings, :type => "boolean ()"
    publish :function => :ReadCardsDatabase, :type => "boolean ()"
    publish :function => :ReadTunersDatabase, :type => "boolean ()"
    publish :function => :GetKernelModuleInfo, :type => "map (string)"
    publish :function => :ReadKernelModules, :type => "boolean ()"
    publish :function => :GetMajor81Aliases, :type => "list <string> (path)", :private => true
    publish :function => :GetMajorInstalls, :type => "list <string> (path)", :private => true
    publish :function => :ReadModuleParameters, :type => "map (path, string)", :private => true
    publish :function => :parse_module_string, :type => "list <string> (string)", :private => true
    publish :function => :read_modprobe, :type => "list (path)", :private => true
    publish :function => :IsFWInstalled, :type => "boolean (string)"
    publish :function => :AskForFirmware, :type => "string (string, string)", :private => true
    publish :function => :AskForFirmwareCached, :type => "string (string, string)", :private => true
    publish :function => :InstallFWCard, :type => "boolean (string, string, integer, integer, string, boolean)", :private => true
    publish :function => :RequiredModules, :type => "list <string> (boolean)"
    publish :function => :FirmwareDrivers, :type => "list <string> ()", :private => true
    publish :function => :InstallFW, :type => "boolean ()", :private => true
    publish :function => :ReadSettings, :type => "boolean ()"
    publish :function => :WriteModulesParameters, :type => "boolean (map)", :private => true
    publish :function => :GetStaticConfig, :type => "string (string)", :private => true
    publish :function => :RemoveHWConfigTV, :type => "boolean ()", :private => true
    publish :function => :LoadBlackList, :type => "void ()", :private => true
    publish :function => :IsDriverBlacklisted, :type => "boolean (string)", :private => true
    publish :function => :AnyDriverBlacklisted, :type => "boolean (list <string>)", :private => true
    publish :function => :IsModaliasBlacklisted, :type => "boolean (string)", :private => true
    publish :function => :IsCardBlacklisted, :type => "boolean (map)"
    publish :function => :FixBlackListFile, :type => "void ()", :private => true
    publish :function => :WriteSettings, :type => "boolean ()", :private => true
    publish :function => :WriteSoundVolume, :type => "boolean ()", :private => true
    publish :function => :Detect, :type => "boolean ()"
    publish :function => :InstalledCardsSummary, :type => "list ()"
    publish :function => :CardGet, :type => "any (integer)"
    publish :function => :CardGetUniq, :type => "map (string)"
    publish :function => :CardAddCurrent, :type => "integer ()"
    publish :function => :CardReplaceWithCurrent, :type => "boolean (integer)"
    publish :function => :CardRemove, :type => "boolean (integer)"
    publish :function => :CardsUniqueKeys, :type => "list ()"
    publish :function => :CardIndexUniqKey, :type => "integer (string)"
    publish :function => :CardsAsItems, :type => "list ()"
    publish :function => :CardsAsItemMap, :type => "list <map <string, any>> ()"
    publish :function => :DetectedCardGet, :type => "map (integer)"
    publish :function => :DetectedCardUniqGet, :type => "map (string)"
    publish :function => :IndexDetectedCardUniqGet, :type => "integer (string)"
    publish :function => :DetectedCardsAsItems, :type => "list ()"
    publish :function => :GetTvCard, :type => "map (string, string)"
    publish :function => :CardsDBVendorsAsItems, :type => "list (map, map, string)"
    publish :function => :CardsDBVendorGetCards, :type => "list (map, integer)"
    publish :function => :GetTuner, :type => "map (string, string)"
    publish :function => :TunersDBHasTunersFor, :type => "boolean (string)"
    publish :function => :TunersDBAsItems, :type => "list (string, map)"
    publish :function => :TunersDBSelectTuner, :type => "map (string, integer)"
    publish :function => :ModulesAsItems, :type => "list (map, string)"
    publish :function => :ModuleParametersAsItems, :type => "list (map, string, map)"
    publish :function => :ReadIRC, :type => "any ()"
    publish :function => :WriteIRC, :type => "any ()"
    publish :function => :LoadIRCModulesDescription, :type => "void ()"
    publish :function => :GetIRCModule, :type => "string ()"
    publish :function => :ReadStationsConfig, :type => "map (path)"
    publish :function => :WriteStationsConfig, :type => "boolean ()"
    publish :function => :tv_tmp_start, :type => "string ()"
    publish :function => :InitializeStationsConfig, :type => "boolean ()"
    publish :function => :Read, :type => "boolean (block <boolean>)"
    publish :function => :Write, :type => "boolean (block <boolean>)"
    publish :function => :Import, :type => "boolean (map)"
    publish :function => :Export, :type => "map ()"
    publish :function => :Propose, :type => "void ()"
    publish :function => :Summary, :type => "string ()"
  end

  Tv = TvClass.new
  Tv.main
end

# encoding: utf-8

# File:	clients/tv.ycp
# Package:	TV cards configuration
# Summary:	Main file
# Authors:	Jan Holesovsky <kendy@suse.cz>
#
# $Id$
#
# Main file for tv configuration. Uses all other files.
module Yast
  class TvClient < Client
    def main
      Yast.import "UI"

      #**
      # <h3>Configuration of the TV cards</h3>

      textdomain "tv"

      # The main ()
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("Tv module started")

      Yast.import "Mode"
      Yast.import "Report"
      Yast.import "CommandLine"
      Yast.import "RichText"

      Yast.include self, "tv/ui.rb"

      # Should we suppress Read() and Write()? It is necessary in proposals...
      @no_io = false

      @i = 0
      while Ops.less_than(@i, Builtins.size(WFM.Args))
        if WFM.Args(@i) == path(".noio")
          @no_io = true
        elsif WFM.Args(@i) == path(".test")
          Mode.SetTest("test")
        end
        @i = Ops.add(@i, 1)
      end


      # the command line description map
      @cmdline = {
        "id"         => "tv",
        # translators: command line help text for Tv module
        "help"       => _(
          "TV card configuration module"
        ),
        "guihandler" => fun_ref(method(:TvSequence), "any ()"),
        "initialize" => fun_ref(method(:TvRead), "boolean ()"),
        "finish"     => fun_ref(method(:TvWrite), "boolean ()"),
        "actions"    => {
          "summary" => {
            "handler" => fun_ref(method(:SummaryHandler), "boolean (map)"),
            # translators: command line help text for summary action
            "help"    => _(
              "Configuration summary of TV cards"
            )
          },
          "add"     => {
            "handler"         => fun_ref(
              method(:AddCardHandler),
              "boolean (map)"
            ),
            # translators: command line help text for add action
            "help"            => _(
              "Add TV card. Without parameters, add the first one detected."
            ),
            "options"         => ["non_strict"],
            # help text for unknown parameters
            "non_strict_help" => _(
              "Value of the specific module parameter"
            )
          },
          "remove"  => {
            "handler" => fun_ref(method(:RemoveCardHandler), "boolean (map)"),
            # translators: command line help text for remove action
            "help"    => _(
              "Remove TV or radio card"
            )
          },
          "modules" => {
            "handler" => fun_ref(method(:ListModulesHandler), "boolean (map)"),
            # translators: command line help text for modules action
            "help"    => _(
              "List all available TV kernel modules (drivers)"
            )
          },
          "cards"   => {
            "handler" => fun_ref(method(:ListModelsHandler), "boolean (map)"),
            # translators: command line help text for 'cards' action
            "help"    => _(
              "List supported TV models with their ID numbers"
            )
          },
          "set"     => {
            "handler"         => fun_ref(
              method(:SetParametersHandler),
              "boolean (map)"
            ),
            # translators: command line help text for set action
            "help"            => _(
              "Set the new values for given card parameters"
            ),
            "options"         => ["non_strict"],
            # command line help text for 'add'
            "non_strict_help" => _(
              "Value of the specific module parameter"
            )
          },
          "show"    => {
            "handler" => fun_ref(method(:ShowCardHandler), "boolean (map)"),
            # translators: command line help text for 'show'
            "help"    => _(
              "Show the information of the given TV card"
            )
          },
          "irc"     => {
            "handler" => fun_ref(
              method(:IRCHandler),
              "boolean (map <string, string>)"
            ),
            # translators: command line help text for 'irc'
            "help"    => _(
              "Enable or disable infrared control"
            )
          }
        },
        "options"    => {
          "no"      => {
            # translators: command line help text for the 'no' option
            "help" => _(
              "TV or radio card number"
            ),
            "type" => "string"
          },
          "tuner"   => {
            # translators: command line help text for the 'tuner' option
            "help" => _(
              "TV tuner type"
            ),
            "type" => "string"
          },
          "module"  => {
            # translators: command line help text for the 'module' option
            "help" => _(
              "Kernel module (driver) for the TV or radio card"
            ),
            "type" => "string"
          },
          "card"    => {
            # translators: command line help text for the 'card' option
            "help" => _(
              "ID of specific TV card model. Use the 'cards' command to see the list of possible values."
            ),
            "type" => "string"
          },
          "radio"   => {
            # translators: command line help text for the 'radio' option
            "help" => _(
              "List radio modules instead of TV ones"
            )
          },
          "enable"  => {
            # translators: command line help text for the 'enable' option
            "help" => _(
              "Enable IRC"
            )
          },
          "disable" => {
            # translators: command line help text for the 'disable' option
            "help" => _(
              "Disable IRC"
            )
          },
          "status"  => {
            # translators: command line help text for the 'status' option
            "help" => _(
              "Show current status of IRC"
            )
          }
        },
        "mappings" =>
          #FIXME use irc client! + "module" option
          {
            "summary" => [],
            "add"     => ["no", "tuner", "card", "module"],
            "set"     => ["no", "tuner", "card"],
            #TODO edit alias
            "modules" => ["radio"],
            "cards"   => ["module"],
            "show"    => ["no"],
            "remove"  => ["no"],
            #delete alias
            "irc"     => ["enable", "disable", "status"]
          }
      }

      # --------------------------------------------------------------------------

      @ret = nil
      if @no_io
        @ret = TvSequenceNoIO()
      else
        @ret = CommandLine.Run(@cmdline)
      end

      Builtins.y2debug("ret == %1", @ret)

      # Finish
      Builtins.y2milestone("Tv module finished")
      Builtins.y2milestone("----------------------------------------")
      deep_copy(@ret) 

      # EOF
    end

    # --------------------------------------------------------------------------
    # --------------------------------- cmd-line handlers

    # Print summary of basic options
    # @return [Boolean] false
    def SummaryHandler(options)
      options = deep_copy(options)
      CommandLine.Print(RichText.Rich2Plain(Tv.Summary))
      false # do not call Write...
    end


    # Handler for adding a card via command line
    # @param [Hash] options parameters passed as cmdline args
    # @return [Boolean] true on success
    def AddCardHandler(options)
      options = deep_copy(options)
      card_no = Builtins.tointeger(Ops.get_string(options, "no", "-1"))
      card_model = Ops.get_string(options, "card", "-1")
      modname = Ops.get_string(options, "module", "")
      card = {}

      # add the detected card
      if card_no == -1 && modname == "" && card_model == "-1"
        card_no = 0 # first detected card
      end

      card = Tv.DetectedCardGet(card_no)

      # add the card manualy
      if card == {}
        if modname == "" && card_model == "-1"
          # error message
          Report.Error(_("The specified card does not exist."))
          return false
        end
        if card_model == "-1"
          Tv.ReadKernelModules
          if !Builtins.haskey(Tv.kernel_modules, modname) &&
              !Builtins.haskey(Tv.radio_modules, modname)
            # error message, %1 is module (driver) name
            Report.Error(
              Builtins.sformat(
                _("The specified card does not exist. Module %1 is unknown."),
                modname
              )
            )
            return false
          end
          card = { "module" => modname, "name" => _("User-Defined TV Card") }
          if Builtins.haskey(Tv.radio_modules, modname)
            Ops.set(card, "name", _("User-Defined Radio Card"))
            Ops.set(card, "radio", true)
          end
        else
          card = Tv.GetTvCard(card_model, modname)
          if card == {}
            # error message
            Report.Error(
              _(
                "The specified card does not exist. Probably the driver or card model is wrong."
              )
            )
            return false
          end
          options = Builtins.remove(options, "card")
        end
        if Builtins.haskey(options, "module")
          options = Builtins.remove(options, "module")
        end
      end
      if Builtins.contains(
          Tv.CardsUniqueKeys,
          Ops.get_string(card, "unique_key", "")
        )
        #error message, %1 is name
        Report.Message(
          Builtins.sformat(
            _("The card '%1' is already configured."),
            Ops.get_string(card, "name", "")
          )
        )
        return false
      end

      Ops.set(card, "parameters", {}) if !Builtins.haskey(card, "parameters")

      # add tuner parameters
      tuner_id = Ops.get_string(options, "tuner")
      if tuner_id != nil
        Ops.set(card, ["parameters", "tuner"], tuner_id)
        options = Builtins.remove(options, "tuner")
      end
      options = Builtins.remove(options, "no") if Builtins.haskey(options, "no")

      # add more parameters
      if Ops.greater_than(Builtins.size(options), 0)
        kernel_module = Tv.GetKernelModuleInfo(
          Ops.get_string(card, "module", "")
        )
        Builtins.foreach(
          Convert.convert(
            options,
            :from => "map",
            :to   => "map <string, string>"
          )
        ) do |option, val|
          if Builtins.haskey(kernel_module, option)
            Ops.set(card, ["parameters", option], val)
          end
        end
      end

      # TODO add sound card number automatically?
      #    card ["sound_card_no"] = ...

      Tv.current_card = deep_copy(card)
      Tv.CardAddCurrent # return value is card index

      true
    end

    # Handler for setting the paramerer values of tv card
    # @param [Hash] options parameters on command line
    # @return [Boolean] success
    def SetParametersHandler(options)
      options = deep_copy(options)
      card_no = Builtins.tointeger(Ops.get_string(options, "no", "-1"))
      if card_no == -1
        #error message
        Report.Error(_("Specify the card number."))
        return false
      end
      card = Convert.to_map(Tv.CardGet(card_no))
      if Builtins.size(card) == 0
        #error message, %1 is number
        Report.Error(
          Builtins.sformat(_("There is no card with number %1."), card_no)
        )
        return false
      end
      options = Builtins.remove(options, "no")

      # add more parameters
      if Ops.greater_than(Builtins.size(options), 0)
        kernel_module = Tv.GetKernelModuleInfo(
          Ops.get_string(card, "module", "")
        )
        Builtins.foreach(
          Convert.convert(
            options,
            :from => "map",
            :to   => "map <string, string>"
          )
        ) do |option, val|
          if Builtins.haskey(kernel_module, option)
            Ops.set(card, ["parameters", option], val)
          end
        end
      end
      Tv.current_card = deep_copy(card)
      Tv.CardReplaceWithCurrent(card_no)
    end


    # Handler for adding a card via command line
    # @param [Hash] options parameters passed as cmdline args
    # @return [Boolean] true on success
    def RemoveCardHandler(options)
      options = deep_copy(options)
      card_no = Builtins.tointeger(Ops.get_string(options, "no", "-1"))
      if card_no == -1
        #error message
        Report.Error(_("Specify the card number."))
        return false
      end
      card = Convert.to_map(Tv.CardGet(card_no))
      if Builtins.size(card) == 0
        #error message, %1 is number
        Report.Error(
          Builtins.sformat(_("There is no card with number %1."), card_no)
        )
        return false
      end
      Tv.CardRemove(card_no)
    end

    # Handler for showing TV card information
    # @param [Hash] options parameters on command line
    # @return [Boolean] false (no write)
    def ShowCardHandler(options)
      options = deep_copy(options)
      card_no = Builtins.tointeger(Ops.get_string(options, "no", "-1"))
      card_no = 0 if card_no == -1

      if card_no == -1
        #error message
        Report.Error(_("Specify the card number."))
        return false
      end
      card = Convert.to_map(Tv.CardGet(card_no))
      if Builtins.size(card) == 0
        #error message, %1 is number
        Report.Error(
          Builtins.sformat(_("There is no card with number %1."), card_no)
        )
        return false
      end

      modname = Ops.get_string(card, "module", "")
      # list of card parameters will follow; %1 is card name, %2 driver
      out = Builtins.sformat(
        _("Parameters of Card '%1' (using module %2):\n"),
        Ops.get_string(card, "name", ""),
        modname
      )

      kernel_module = Tv.GetKernelModuleInfo(modname)
      Builtins.foreach(
        Convert.convert(
          kernel_module,
          :from => "map",
          :to   => "map <string, string>"
        )
      ) do |option, val|
        next if option == "module_description" || option == "module_author"
        out = Ops.add(
          Ops.add(Ops.add(out, Builtins.sformat("\n%1", option)), "\n\t"),
          val
        )
        if Ops.get(card, ["parameters", option]) != nil
          # label (current value of sound module parameter)
          out = Ops.add(
            out,
            Builtins.sformat(
              _("\n\tCurrent Value: %1\n"),
              Ops.get_string(card, ["parameters", option], "")
            )
          )
        end
      end
      CommandLine.Print(out)
      false # write not necessary
    end

    # Handler for listing available tv models
    def ListModelsHandler(options)
      options = deep_copy(options)
      modname = Ops.get_string(options, "module", "")
      out = {}
      Builtins.foreach(
        Convert.convert(Tv.cards_database, :from => "list", :to => "list <map>")
      ) { |vendor| Builtins.foreach(Ops.get_list(vendor, "cards", [])) do |card|
        id = Builtins.tointeger(
          Ops.get_string(card, ["parameters", "card"], "0")
        )
        next if id == nil
        Ops.set(
          out,
          id,
          Builtins.add(
            Ops.get_list(out, id, []),
            Builtins.sformat(
              "%1 (%2)",
              Ops.get_string(card, "name", ""),
              Ops.get_string(card, "module", "")
            )
          )
        )
      end }
      Builtins.foreach(
        Convert.convert(
          out,
          :from => "map",
          :to   => "map <integer, list <string>>"
        )
      ) do |id, cards|
        CommandLine.Print(Builtins.sformat("%1", id))
        Builtins.foreach(cards) { |c| CommandLine.Print(Ops.add(" ", c)) }
      end
      false
    end

    # Handler for listing available kernel modules for tv
    def ListModulesHandler(options)
      options = deep_copy(options)
      Tv.ReadKernelModules
      modules = Builtins.haskey(options, "radio") ?
        Tv.radio_modules :
        Tv.kernel_modules
      Builtins.foreach(
        Convert.convert(modules, :from => "map", :to => "map <string, map>")
      ) do |key, value|
        space = "\t"
        CommandLine.Print(
          Ops.add(
            Ops.add(key, space),
            Ops.get_string(value, "module_description", "")
          )
        )
      end
      false
    end

    # Handler for enabling/disabling IRC
    def IRCHandler(options)
      options = deep_copy(options)
      command = CommandLine.UniqueOption(
        options,
        ["enable", "disable", "status"]
      )

      if command == "status"
        if !Tv.use_irc
          # command line status text
          CommandLine.Print(_("Infrared control is disabled"))
        else
          # command line status text
          CommandLine.Print(
            Builtins.sformat(
              _("Infrared control is enabled using module %1"),
              Tv.irc_module
            )
          )
        end
        return false
      end

      Tv.irc_modified = Tv.irc_modified || command == "enable" && !Tv.use_irc ||
        command == "diasble" && Tv.use_irc
      Tv.use_irc = command == "enable"
      #    Tv::irc_module	= TODO

      Tv.irc_modified
    end

    # Wrapper function for reading the settings (used by cmd-line)
    # @return [Boolean] success
    def TvRead
      abort_block = lambda { false }
      Tv.Read(abort_block)
    end

    # Wrapper function for writing the settings (used by cmd-line)
    # @return [Boolean] success
    def TvWrite
      abort_block = lambda { false }
      Tv.Write(abort_block)
    end
  end
end

Yast::TvClient.new.main

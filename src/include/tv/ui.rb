# encoding: utf-8

# File:	include/tv/ui.ycp
# Package:	TV cards configuration
# Summary:	User interface functions.
# Authors:	Jan Holesovsky <kendy@suse.cz>
#
# $Id$
#
# All user interface functions.
module Yast
  module TvUiInclude
    def initialize_tv_ui(include_target)
      Yast.import "UI"

      textdomain "tv"

      Yast.import "Label"
      Yast.import "Package"
      Yast.import "Popup"
      Yast.import "Sequencer"
      Yast.import "String"
      Yast.import "Summary"
      Yast.import "Tv"
      Yast.import "Wizard"
      Yast.import "UIHelper"
      Yast.import "WizardHW"
      Yast.import "Mode"

      Yast.include include_target, "tv/helps.rb"
      Yast.include include_target, "tv/misc.rb"
      Yast.include include_target, "tv/irc_ui.rb"

      @selected_card = ""
    end

    # Read settings dialog
    # @return Symbol for next or abort dialog.
    def ReadDialog
      # Set help text
      Wizard.RestoreHelp(ReadDialogHelp())

      # A callback function for abort
      callback = lambda { UI.PollInput == :abort }

      # Read the configuration
      was_ok = Tv.Read(callback)

      was_ok ? :next : :abort
    end

    # Write settings dialog
    # @return Symbol for next or abort dialog.
    def WriteDialog
      # Set help text
      Wizard.RestoreHelp(WriteDialogHelp())
      Wizard.DisableAbortButton

      callback = lambda { UI.PollInput == :abort }
      # Write the configuration
      was_ok = Tv.Write(callback)

      was_ok ? :next : :abort
    end

    # Just a wrapper for Tv::CardAddCurrent() to be used in the wizard sequencer.
    # @return Symbol for next dialog.
    def CardAddCurrentWrapper
      Tv.CardAddCurrent
      :next
    end

    # Just a wrapper for Tv::CardReplaceWithCurrent() to be used in the wizard sequencer.
    # @return Symbol for next dialog.
    def CardReplaceWithCurrentWrapper
      Tv.CardReplaceWithCurrent(Tv.current_card_no)
      :next
    end

    def SetItems
      # create description for WizardHW
      items = Tv.CardsAsItemMap
      Builtins.y2debug("items: %1", items)

      WizardHW.SetContents(items)
      Wizard.SetDesktopTitleAndIcon("tv")

      nil
    end


    # A dialog showing the detected cards and allowing to configure them.
    # @return [Object] The value of the resulting UserInput.
    def HardwareDialog
      WizardHW.CreateHWDialog(
        _("TV and Radio Card Configuration"),
        DetectedDialogHelp(),
        [_("Number"), _("Card Name")],
        []
      )

      Wizard.SetNextButton(:next, Label.OKButton)
      Wizard.SetAbortButton(:abort, Label.CancelButton)

      Wizard.HideBackButton if !Mode.installation

      ret = :_dummy
      begin
        SetItems()

        # initialize selected_card
        @selected_card = WizardHW.SelectedItem if @selected_card == ""

        # set previously selected card
        WizardHW.SetSelectedItem(@selected_card)

        ev = WizardHW.WaitForEvent
        Builtins.y2milestone("WaitForEvent: %1", ev)

        ui = Ops.get_symbol(ev, ["event", "ID"])

        # remember the selected card
        @selected_card = Ops.get_string(ev, "selected", "")

        if ui == :add
          Tv.current_card = {}
          Tv.current_card_no = nil
          ret = :add_manually
        elsif ui == :edit
          index_configured = Tv.CardIndexUniqKey(
            Ops.get_string(ev, "selected", "")
          )
          index_detected = Tv.IndexDetectedCardUniqGet(
            Ops.get_string(ev, "selected", "")
          )

          Builtins.y2debug("index_detected: %1", index_detected)
          Builtins.y2debug("index_configured: %1", index_configured)

          if index_configured != nil
            Tv.current_card = Convert.to_map(Tv.CardGet(index_configured))
            Tv.current_card_no = index_configured

            # TODO		if (sel_no > 63)
            # 		    ret = `edit_button_radio;
            # 		else
            ret = :edit
          elsif index_detected != nil
            Tv.current_card = Tv.DetectedCardUniqGet(
              Ops.get_string(ev, "selected", "")
            )
            Tv.current_card_no = nil

            # check whether module was found
            module_found = false

            if Ops.is_string?(Ops.get(Tv.current_card, "module"))
              module_found = Ops.get_string(Tv.current_card, "module", "") == ""
            else
              module_found = Ops.greater_than(
                Builtins.size(Ops.get_list(Tv.current_card, "module", [])),
                0
              )
            end

            # display a confirmation popup if the card is blacklisted
            if Tv.IsCardBlacklisted(Tv.current_card)
              if !Popup.ContinueCancel(
                  Builtins.sformat(
                    _(
                      "Card '%1' (or its driver) is currently disabled.\n" +
                        "\n" +
                        "There might be serious reasons for this like:\n" +
                        "- the card is not supported by the driver,\n" +
                        "- the driver does not work correctly with this card,\n" +
                        "- enabling the card may make the system unstable or freeze it.\n" +
                        "\n" +
                        "Really configure and enable the card?\n"
                    ),
                    Ops.get_string(Tv.current_card, "name", "")
                  )
                )
                next
              end

              Builtins.y2warning("Configuring a blacklisted card")
            end

            if !module_found
              ret = :add_manually_warn
            else
              ret = :add_detected
            end
          end
        elsif ui == :delete
          Builtins.y2debug("selected: %1", Ops.get_string(ev, "selected", ""))
          index = Tv.CardIndexUniqKey(Ops.get_string(ev, "selected", ""))
          Builtins.y2debug("index: %1", index)

          if index != nil
            Tv.current_card = Convert.to_map(Tv.CardGet(index))
            Tv.current_card_no = index

            # The user chose [Delete] in the overview dialog
            # %1 is name of the selected card
            really_del = Popup.YesNo(
              Builtins.sformat(
                _("Really\nremove the configuration\nof %1?"),
                Ops.get_string(Tv.current_card, "name", "")
              )
            )

            Tv.CardRemove(index) if really_del
          end
        elsif ui == :cancel
          ret = :abort
        else
          ret = ui
        end
      end while !Builtins.contains(
        [
          :back,
          :abort,
          :next,
          :add_manually,
          :add_manually_warn,
          :add_detected,
          :edit,
          :edit_button_radio
        ],
        ret
      )

      Wizard.RestoreNextButton
      Wizard.RestoreBackButton if !Mode.installation

      ret
    end


    # Constructs the cards selection box for the selected vendor.
    # @param [Array] vendor_cards_db List of cards provided by the selected vendor.
    # @param [Hash] parameters The current parameters to preselect the right model.
    # @param mod kernel module for the selected card (nil for none/not known)
    # @return [Yast::Term] The selection box.
    def CardsSelectionBox(vendor_cards_db, parameters, modules)
      vendor_cards_db = deep_copy(vendor_cards_db)
      parameters = deep_copy(parameters)
      modules = deep_copy(modules)
      Builtins.y2debug("vendor_cards_db: %1", vendor_cards_db)
      Builtins.y2debug("parameters: %1", parameters)
      Builtins.y2debug("modules: %1", modules)

      card_no = 0
      some_is_selected = false
      vendor_cards_items = Builtins.maplist(
        Convert.convert(vendor_cards_db, :from => "list", :to => "list <map>")
      ) do |card|
        select_this = false
        card_modules = Ops.get_list(card, "module", [])
        if !some_is_selected && (modules == nil || modules == card_modules)
          #	    select_this = CmpParameters (card["parameters",current_module]:$[],parameters);
          select_this = Ops.get_map(card, "parameters", {}) == parameters
          if select_this
            Builtins.y2debug(
              "card params: %1",
              Ops.get_map(card, "parameters", {})
            )
            Builtins.y2debug("parameters: %1", parameters)
          end
        end
        ret = Item(
          Id(card_no),
          Ops.get_string(card, "name", ""),
          select_this && !some_is_selected
        )
        some_is_selected = true if select_this
        card_no = Ops.add(card_no, 1)
        deep_copy(ret)
      end

      # SelectionBox label:
      SelectionBox(
        Id(:cards_selbox),
        Opt(:notify),
        _("&Card"),
        vendor_cards_items
      )
    end

    # A popup allowing to choose the tuner type.
    # @param [String] kernel_module Name of the kernel module for the selected TV card.
    # @param [Hash] selected_tuner The previously selected tuner (to be preselected again).
    # @return [Hash] The selected tuner or nil if cancelled.
    def ChooseTuner(kernel_module, selected_tuner)
      selected_tuner = deep_copy(selected_tuner)
      # Currently selected tuner
      sel_tuner = {}

      contents = VBox(
        SelectionBox(
          Id(:tuners_selbox),
          # SelectionBox label:
          _("&Tuner"),
          Tv.TunersDBAsItems(kernel_module, selected_tuner)
        ),
        VSpacing(0.3),
        ButtonBox(
          PushButton(Id(:ok), Label.OKButton),
          PushButton(Id(:cancel), Label.CancelButton)
        )
      )

      UI.OpenDialog(UIHelper.SizeAtLeast(contents, 40.0, 10.0))

      ret = nil
      begin
        ret = UI.UserInput

        if ret == :ok
          sel_no = Convert.to_integer(
            UI.QueryWidget(Id(:tuners_selbox), :CurrentItem)
          )
          if sel_no != nil
            sel_tuner = Tv.TunersDBSelectTuner(kernel_module, sel_no)
          else
            # For translators: The user chose [OK] but did not select a tuner
            Popup.Message(_("Select your tuner."))
            ret = nil
          end
        end
      end while ret != :ok && ret != :cancel

      UI.CloseDialog

      if ret == :ok
        Builtins.y2debug("selected tuner: %1", sel_tuner)
        return deep_copy(sel_tuner)
      end
      nil
    end

    # A dialog allowing the manual selection of the card.
    # @param [Boolean] warn Display warning, that the card was not fully detected.
    # @return [Object] The value of the resulting UserInput.
    def ManualDialog(warn)
      # For translators: Header of the dialog
      caption = _("Manual TV Card Selection")

      # The selected card
      selected_card = deep_copy(Tv.current_card)

      # Parameters and module name of the current card
      current_card_parameters = Ops.get_map(Tv.current_card, "parameters", {})

      module_names_tmp = Convert.convert(
        Ops.get(Tv.current_card, "module"),
        :from => "any",
        :to   => "list <string>"
      )
      module_name_tmp = Ops.get(
        module_names_tmp,
        Ops.subtract(Builtins.size(module_names_tmp), 1),
        ""
      )

      # The selected tuner
      # TODO: module "tuner" instead of module_name_tmp??
      selected_tuner = Tv.GetTuner(
        module_name_tmp,
        Ops.get_string(
          current_card_parameters,
          [module_name_tmp, "tuner"],
          "-1"
        )
      )

      # We must remember the current card if it was autodetected
      autodetected_card = {}
      if module_name_tmp != nil && module_name_tmp != "" &&
          Ops.get_string(current_card_parameters, ["bttv", "card"], "-1") == "-1"
        autodetected_card = deep_copy(Tv.current_card)
      end
      # The currently selected vendor
      selected_vendor = nil

      # A list of all the vendors and all the cards for the SelectionBox widgets
      all_vendors = []

      # A list of the cards of the selected vendor
      vendor_cards_db = []

      # Initialize all_vendors and selected_vendor
      vendors_and_selected = Tv.CardsDBVendorsAsItems(
        autodetected_card,
        Ops.get_map(current_card_parameters, module_name_tmp, {}),
        module_name_tmp
      )

      all_vendors = Ops.get_list(vendors_and_selected, 0, [])
      selected_vendor = Ops.get_integer(vendors_and_selected, 1)

      Builtins.y2debug("Selected vendor: %1", selected_vendor)

      if selected_vendor != nil
        vendor_cards_db = Tv.CardsDBVendorGetCards(
          autodetected_card,
          selected_vendor
        )
      end

      tuner_button = Right(
        PushButton(
          Id(:tuner_button),
          Opt(:key_F3),
          # PushButton label:
          _("&Tuner...")
        )
      )

      contents = HBox(
        HSpacing(1.5),
        VBox(
          VSpacing(1.0),
          # Frame label
          Frame(
            _("Card Type"),
            HBox(
              HSpacing(0.5),
              VBox(
                VSpacing(0.2),
                VBox(
                  HBox(
                    SelectionBox(
                      Id(:vendors_selbox),
                      # SelectioBox label:
                      Opt(:notify),
                      _("&Vendor"),
                      all_vendors
                    ),
                    ReplacePoint(
                      Id(:cards_rep),
                      CardsSelectionBox(
                        vendor_cards_db,
                        current_card_parameters,
                        module_names_tmp
                      )
                    )
                  ),
                  ReplacePoint(Id(:tuners_rep), tuner_button)
                ),
                VSpacing(0.2)
              ),
              HSpacing(0.5)
            )
          ),
          VSpacing(0.5),
          HCenter(
            HBox(
              PushButton(
                Id(:details_button),
                Opt(:key_F7),
                # PushButton label:
                _("&Expert Settings...")
              ),
              # PushButton label:
              PushButton(Id(:channels), Opt(:key_F8), _("TV &Channels..."))
            )
          )
        ),
        HSpacing(1.5)
      )

      Wizard.SetContentsButtons(
        caption,
        contents,
        ManualDialogHelp(),
        Label.BackButton,
        Label.NextButton
      )

      if warn && Ops.get(Tv.current_card, "module") == nil # FIXME??
        # For translators: A warning popup
        Popup.Message(
          _(
            "The selected card does not provide full\n" +
              "information for automatic detection.\n" +
              "Select the exact type from\n" +
              "the list in the following dialog."
          )
        )
      end

      ret = nil

      UI.SetFocus(Id(:vendors_selbox))

      if Ops.get_boolean(Tv.current_card, "dvb", false)
        # disable TV channel setup for DVB cards
        # DVB scan is currently unsupported
        UI.ChangeWidget(Id(:channels), :Enabled, false)
        Builtins.y2milestone("DVB card - disabling TV channel setup button")
      end
      begin
        # Disable/enable the [Select tuner] button
        module_names = Ops.get_list(selected_card, "module", [])
        module_name = Ops.get(
          module_names,
          Ops.subtract(Builtins.size(module_names), 1),
          ""
        )

        has_tuners = Tv.TunersDBHasTunersFor(module_name)
        selected_tuner = {} if !has_tuners
        if selected_tuner != {}
          UI.ReplaceWidget(
            Id(:tuners_rep),
            HBox(
              HSpacing(0.5),
              # label, %1 is tuner type
              Label(
                Builtins.sformat(
                  _("Tuner: %1"),
                  Ops.get_string(selected_tuner, "name", "")
                )
              ),
              tuner_button
            )
          )
        else
          UI.ReplaceWidget(Id(:tuners_rep), HBox(tuner_button))
        end

        # User input
        ret = tvUserInput

        Builtins.y2debug("UI: %1", ret)

        # Update the list of the cards
        if ret == :vendors_selbox
          current_vendor = selected_vendor
          selected_vendor = Convert.to_integer(
            UI.QueryWidget(Id(:vendors_selbox), :CurrentItem)
          )

          Builtins.y2debug("selected_vendor: %1", selected_vendor)
          Builtins.y2debug("current_vendor: %1", current_vendor)
          if selected_vendor != current_vendor
            vendor_cards_db = Tv.CardsDBVendorGetCards(
              autodetected_card,
              selected_vendor
            )
            UI.ReplaceWidget(
              Id(:cards_rep),
              CardsSelectionBox(vendor_cards_db, nil, nil)
            )
            selected_tuner = {}

            Builtins.y2debug("CardsSelectionBox called with nil params")
          end
        end

        sel_no = Convert.to_integer(
          UI.QueryWidget(Id(:cards_selbox), :CurrentItem)
        )

        if ret == :next && sel_no == nil
          # For translators: The user chose [Next] but did not select a card
          Popup.Message(_("Select your card."))
          ret = nil
        end

        # Update the selection
        if ret == :cards_selbox
          new_card = {}
          new_card = Ops.get_map(vendor_cards_db, sel_no, {}) if sel_no != nil

          if Ops.get_string(new_card, ["parameters", "bttv", "card"], "") !=
              Ops.get_string(selected_card, ["parameters", "bttv", "card"], "") ||
              Ops.get_list(new_card, "module", []) !=
                Ops.get_list(selected_card, "module", [])
            selected_card = deep_copy(new_card)
            selected_tuner = {}
            Builtins.y2debug("Selected card: %1", selected_card)
          end
        end

        # Show a popup with the selection of the tuner
        if ret == :tuner_button
          if sel_no == nil
            # message popup
            Popup.Message(_("Select your card."))
          else
            if has_tuners
              new_tuner = ChooseTuner(module_name, selected_tuner)
              selected_tuner = deep_copy(new_tuner) if new_tuner != nil
            else
              # message popup
              Popup.Message(_("No tuner is available\nfor the selected card."))
            end
          end
        end
      end while ret != :details_button && ret != :channels && ret != :back &&
        ret != :abort &&
        ret != :next

      # hack for ncurses selection (first card is selected as a default):
      if ret == :next && selected_card == {}
        selected_card = Ops.get_map(vendor_cards_db, 0, {})
      end

      # Overwrite the Tv::current_card
      if ret != :back && ret != :abort
        # add the card
        Tv.current_card = Builtins.union(Tv.current_card, selected_card)

        card_parameters = Ops.get_map(selected_card, "parameters", {})
        tuner_parameters = Ops.get_map(selected_tuner, "parameters", {})

        Builtins.y2debug("card_parameters: %1", card_parameters)
        Builtins.y2debug("tuner_parameters: %1", tuner_parameters)

        module_names = Ops.get_list(selected_card, "module", [])
        module_name = Ops.get(
          module_names,
          Ops.subtract(Builtins.size(module_names), 1),
          ""
        )

        Ops.set(
          card_parameters,
          module_name,
          Builtins.union(
            Ops.get_map(card_parameters, module_name, {}),
            tuner_parameters
          )
        )
        Builtins.y2debug("card_parameters: %1", card_parameters)

        Tv.current_card = Builtins.add(
          Tv.current_card,
          "parameters",
          card_parameters
        )

        Builtins.y2milestone(
          "Tv::current_card was updated to %1",
          Tv.current_card
        )
      end

      deep_copy(ret)
    end

    # A dialog allowing the manual selection of the card.
    # @parameter allow_changeoftype if true, additional checkbutton for selecting
    # radio card modules is shown
    # @return [Object] The value of the resulting UserInput.
    def ManualDetailsDialog(allow_changeoftype, index)
      if Tv.kernel_modules == nil
        UI.OpenDialog(
          UIHelper.SpacingAround(
            # Busy popup text (waiting for other action):
            Label(_("Getting list\nof available kernel modules...")),
            1.5,
            1.5,
            0.5,
            0.5
          )
        )

        Tv.ReadKernelModules

        UI.CloseDialog
      end

      # For translators: Header of the dialog
      caption = _("Manual TV and Radio Card Selection: Details")

      # Currently selected module. None => select bttv
      selected_modules = Ops.get_list(Tv.current_card, "module", [])

      selected_module = Ops.get(selected_modules, index)
      selected_module = "bttv" if selected_module == nil

      # And its parameters.
      parameters = Ops.get_map(
        Tv.current_card,
        ["parameters", selected_module],
        {}
      )

      # A list of all the (media/video) kernel modules for the ComboBox widget
      all_modules = Tv.ModulesAsItems(Tv.kernel_modules, selected_module)
      all_radio_modules = Tv.ModulesAsItems(Tv.radio_modules, selected_module)
      all_dvb_modules = Tv.ModulesAsItems(Tv.dvb_modules, selected_module)
      all_dvb_core_drivers = Tv.ModulesAsItems(
        Tv.dvb_core_drivers,
        selected_module
      )

      # The currently selected parameter
      selected_parameter = ""

      # For translators: Label for the TextEntry. %1 means name of the kernel module's parameter.
      parameter_label = _("&Parameter %1")
      # For translators: Label for the TextEntry, when kernel module has no parameters.
      parameter_label_nil = _("&Parameter (none)")

      radio = Ops.get_boolean(Tv.current_card, "radio", false)
      dvb = Ops.get_boolean(Tv.current_card, "dvb", false)

      if dvb
        # don't offer radio card modules for DVB cards
        allow_changeoftype = false
      end

      contents = HBox(
        HSpacing(1.5),
        VBox(
          VSpacing(1.0),
          ReplacePoint(
            Id(:modules_rp),
            ComboBox(
              Id(:module_combo),
              Opt(:hstretch, :notify),
              # ComboBox label:
              _("&Kernel Module"),
              []
            )
          ),
          # Frame label:
          Frame(
            _("Module Parameters"),
            HBox(
              HSpacing(0.5),
              VBox(
                VSpacing(0.2),
                VBox(
                  Table(
                    Id(:parameters_table), #						  Tv::KernelModuleParametersAsItems(selected_module,
                    #										    parameters)
                    Opt(:notify, :immediate),
                    # Header of a table with kernel module params.
                    Header(
                      _("Parameter"),
                      # Header of a table with kernel module params.
                      _("Value"),
                      # Header of a table with kernel module params.
                      _("Description")
                    ),
                    []
                  ),
                  VSquash(
                    HBox(
                      TextEntry(
                        Id(:parameter_entry),
                        Builtins.sformat(parameter_label, selected_parameter)
                      ),
                      Bottom(
                        PushButton(
                          Id(:set_button),
                          # PushButton label
                          _("&Set")
                        )
                      ),
                      Bottom(
                        PushButton(
                          Id(:reset_button),
                          # PushButton label
                          _("R&eset")
                        )
                      )
                    )
                  )
                ),
                VSpacing(0.2)
              ),
              HSpacing(0.5)
            )
          ),
          VSpacing(0.5),
          allow_changeoftype ?
            Left(
              CheckBox(
                Id(:radio_ch),
                Opt(:notify),
                # checkbox label
                _("R&adio Card Modules"),
                radio
              )
            ) :
            VSpacing(0),
          VSpacing(0.5)
        ),
        HSpacing(1.5)
      )

      Wizard.SetContentsButtons(
        caption,
        contents,
        ManualDetailsDialogHelp(allow_changeoftype),
        Label.BackButton,
        Label.NextButton
      )

      if dvb
        if index == 1
          UI.ReplaceWidget(
            Id(:modules_rp),
            ComboBox(
              Id(:module_combo),
              Opt(:hstretch, :notify),
              _("&Kernel Module"),
              all_dvb_modules
            )
          )
          selected_module = Convert.to_string(
            UI.QueryWidget(Id(:module_combo), :Value)
          )
          UI.ChangeWidget(
            Id(:parameters_table),
            :Items,
            Tv.ModuleParametersAsItems(
              Tv.dvb_modules,
              selected_module,
              parameters
            )
          )
        else
          UI.ReplaceWidget(
            Id(:modules_rp),
            ComboBox(
              Id(:module_combo),
              Opt(:hstretch, :notify),
              _("&Kernel Module"),
              all_dvb_core_drivers
            )
          )
          selected_module = Convert.to_string(
            UI.QueryWidget(Id(:module_combo), :Value)
          )
          UI.ChangeWidget(
            Id(:parameters_table),
            :Items,
            Tv.ModuleParametersAsItems(
              Tv.dvb_core_drivers,
              selected_module,
              parameters
            )
          )
        end
      elsif !radio
        UI.ReplaceWidget(
          Id(:modules_rp),
          ComboBox(
            Id(:module_combo),
            Opt(:hstretch, :notify),
            _("&Kernel Module"),
            all_modules
          )
        )
        selected_module = Convert.to_string(
          UI.QueryWidget(Id(:module_combo), :Value)
        )
        UI.ChangeWidget(
          Id(:parameters_table),
          :Items,
          Tv.ModuleParametersAsItems(
            Tv.kernel_modules,
            selected_module,
            parameters
          )
        )
      else
        UI.ReplaceWidget(
          Id(:modules_rp),
          ComboBox(
            Id(:module_combo),
            Opt(:hstretch, :notify),
            _("&Kernel Module"),
            all_radio_modules
          )
        )
        selected_module = Convert.to_string(
          UI.QueryWidget(Id(:module_combo), :Value)
        )
        UI.ChangeWidget(
          Id(:parameters_table),
          :Items,
          Tv.ModuleParametersAsItems(
            Tv.radio_modules,
            selected_module,
            parameters
          )
        )
      end

      # Initialize the "Parameter: xyz" label and its value
      selected_parameter = Convert.to_string(
        UI.QueryWidget(Id(:parameters_table), :CurrentItem)
      )
      value = Ops.get_string(parameters, selected_parameter, "")
      if selected_parameter != nil
        UI.ChangeWidget(
          Id(:parameter_entry),
          :Label,
          Builtins.sformat(parameter_label, selected_parameter)
        )
        UI.ChangeWidget(Id(:parameter_entry), :Value, value)
      else
        UI.ChangeWidget(
          Id(:parameter_entry),
          :Label,
          Builtins.sformat(parameter_label_nil)
        )
        UI.ChangeWidget(Id(:parameter_entry), :Enabled, false)
        UI.ChangeWidget(Id(:set_button), :Enabled, false)
        UI.ChangeWidget(Id(:reset_button), :Enabled, false)
      end

      ret = nil
      begin
        ret = tvUserInput
        if ret == :radio_ch
          if dvb
            UI.ReplaceWidget(
              Id(:modules_rp),
              ComboBox(
                Id(:module_combo),
                Opt(:hstretch, :notify),
                # combo label
                _("&Kernel Module"),
                all_dvb_modules
              )
            )
            selected_module = Convert.to_string(
              UI.QueryWidget(Id(:module_combo), :Value)
            )
            UI.ChangeWidget(
              Id(:parameters_table),
              :Items,
              Tv.ModuleParametersAsItems(
                Tv.dvb_modules,
                selected_module,
                parameters
              )
            )
            radio = true
          elsif !radio
            UI.ReplaceWidget(
              Id(:modules_rp),
              ComboBox(
                Id(:module_combo),
                Opt(:hstretch, :notify),
                # combo label
                _("&Kernel Module"),
                all_radio_modules
              )
            )
            selected_module = Convert.to_string(
              UI.QueryWidget(Id(:module_combo), :Value)
            )
            UI.ChangeWidget(
              Id(:parameters_table),
              :Items,
              Tv.ModuleParametersAsItems(
                Tv.radio_modules,
                selected_module,
                parameters
              )
            )
            radio = true
          else
            UI.ReplaceWidget(
              Id(:modules_rp),
              ComboBox(
                Id(:module_combo),
                Opt(:hstretch, :notify),
                _("&Kernel Module"),
                all_modules
              )
            )
            selected_module = Convert.to_string(
              UI.QueryWidget(Id(:module_combo), :Value)
            )
            UI.ChangeWidget(
              Id(:parameters_table),
              :Items,
              Tv.ModuleParametersAsItems(
                Tv.kernel_modules,
                selected_module,
                parameters
              )
            )
            radio = false
          end
          selected_parameter = Convert.to_string(
            UI.QueryWidget(Id(:parameters_table), :CurrentItem)
          )
          UI.ChangeWidget(
            Id(:parameter_entry),
            :Label,
            Builtins.sformat(parameter_label, selected_parameter)
          )
        end

        # The user changes the module in the Combo Box
        if ret == :module_combo
          selected_module = Convert.to_string(
            UI.QueryWidget(Id(:module_combo), :Value)
          )
          parameters = {}

          # Redraw the table
          if dvb
            if index == 1
              UI.ChangeWidget(
                Id(:parameters_table),
                :Items,
                Tv.ModuleParametersAsItems(
                  Tv.dvb_modules,
                  selected_module,
                  parameters
                )
              )
            else
              UI.ChangeWidget(
                Id(:parameters_table),
                :Items,
                Tv.ModuleParametersAsItems(
                  Tv.dvb_core_drivers,
                  selected_module,
                  parameters
                )
              )
            end
          elsif !radio
            UI.ChangeWidget(
              Id(:parameters_table),
              :Items,
              Tv.ModuleParametersAsItems(
                Tv.kernel_modules,
                selected_module,
                parameters
              )
            )
          else
            UI.ChangeWidget(
              Id(:parameters_table),
              :Items,
              Tv.ModuleParametersAsItems(
                Tv.radio_modules,
                selected_module,
                parameters
              )
            )
          end

          selected_parameter = Convert.to_string(
            UI.QueryWidget(Id(:parameters_table), :CurrentItem)
          )

          value2 = Ops.get_string(parameters, selected_parameter, "")
          if selected_parameter != nil
            UI.ChangeWidget(
              Id(:parameter_entry),
              :Label,
              Builtins.sformat(parameter_label, selected_parameter)
            )
            UI.ChangeWidget(Id(:parameter_entry), :Value, value2)
            UI.ChangeWidget(Id(:parameter_entry), :Enabled, true)
            UI.ChangeWidget(Id(:set_button), :Enabled, true)
            UI.ChangeWidget(Id(:reset_button), :Enabled, true)
          else
            UI.ChangeWidget(
              Id(:parameter_entry),
              :Label,
              Builtins.sformat(parameter_label_nil)
            )
            UI.ChangeWidget(Id(:parameter_entry), :Enabled, false)
            UI.ChangeWidget(Id(:set_button), :Enabled, false)
            UI.ChangeWidget(Id(:reset_button), :Enabled, false)
          end
        end
        # The user selects a parameter in the Table
        if ret == :parameters_table
          selected_parameter = Convert.to_string(
            UI.QueryWidget(Id(:parameters_table), :CurrentItem)
          )
          value2 = Ops.get_string(parameters, selected_parameter, "")

          # Change the Text Entry widget
          UI.ChangeWidget(
            Id(:parameter_entry),
            :Label,
            Builtins.sformat(parameter_label, selected_parameter)
          )
          UI.ChangeWidget(Id(:parameter_entry), :Value, value2)
          UI.ChangeWidget(Id(:parameter_entry), :Enabled, true)
          UI.ChangeWidget(Id(:set_button), :Enabled, true)
          UI.ChangeWidget(Id(:reset_button), :Enabled, true)
        end

        # Set the value in the table
        if ret == :set_button
          if selected_parameter == nil || selected_parameter == ""
            # User chose [Set] but did not select a parameter to set
            Popup.Message(_("Select the parameter\nto edit."))
          else
            value2 = Convert.to_string(
              UI.QueryWidget(Id(:parameter_entry), :Value)
            )

            if value2 !=
                Builtins.filterchars(
                  value2,
                  "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_/-+0123456789"
                )
              # User wants to set kernel parameters but string is invalid
              Popup.Message(
                _(
                  "Do not use characters other\nthan a-z, A-Z, _, -, +, /, and 0-9."
                )
              )
            else
              parameters = Builtins.add(parameters, selected_parameter, value2)

              current = Convert.to_string(
                UI.QueryWidget(Id(:parameters_table), :CurrentItem)
              )
              UI.ChangeWidget(
                Id(:parameters_table),
                term(:Item, current, 1),
                value2
              )
            end
          end
        end
        # Reset the value in the table
        if ret == :reset_button
          if selected_parameter == nil || selected_parameter == ""
            # User chose [Set] but did select a parameter she wants to set
            Popup.Message(_("Select the parameter\nto edit."))
          else
            parameters = Builtins.add(parameters, selected_parameter, "")

            current = Convert.to_string(
              UI.QueryWidget(Id(:parameters_table), :CurrentItem)
            )
            UI.ChangeWidget(
              Id(:parameters_table),
              term(:Item, current, 1),
              value
            )
          end
        end
      end while ret != :back && ret != :abort && ret != :next

      # Store the values to Tv::current_card
      if ret != :back && ret != :abort
        if radio
          # For translators: The name of the card is set to "User defined",
          # because the user changed kernel module parameters and so we
          # do not have a good name...
          Ops.set(Tv.current_card, "name", _("User-Defined Radio Card"))
        elsif !dvb # DVB modules don't use card type option
          # For translators: The name of the card is set to "User defined"...
          Ops.set(Tv.current_card, "name", _("User-Defined TV Card"))
        end


        if Ops.greater_than(Builtins.size(selected_modules), 1) || dvb
          Ops.set(selected_modules, index, selected_module)
          Ops.set(Tv.current_card, "module", selected_modules)
          ret = :details1 if index == 0
        else
          Ops.set(Tv.current_card, "module", [selected_module])
        end

        if !Builtins.haskey(Tv.current_card, "parameters")
          # add missing "parameters" map otherwise adding parameter would fail
          Ops.set(Tv.current_card, "parameters", {})
        end

        Ops.set(Tv.current_card, ["parameters", selected_module], parameters)
        Ops.set(Tv.current_card, "radio", radio)
      end
      deep_copy(ret)
    end

    def CheckManualConfig
      ret = :audio

      # require manual configuration for unknown DVB cards
      if Ops.get_boolean(Tv.current_card, "dvb", false) &&
          Ops.get_boolean(Tv.current_card, "unknown", false)
        ret = :manual
      end

      ret
    end

    # A dialog asking if the card is connected to the sound card.
    # @return [Object] The value of the resulting UserInput.
    def AudioDialog
      # For translators: Header of the dialog
      caption = _("Audio for TV and Radio Card")

      # Name of the TV card being currently configured
      current_card_name = Ops.get_string(Tv.current_card, "name", "")
      current_card_name = "" if current_card_name == nil

      # A list of the sound cards in the form allowed by the Table widet
      sound_cards = SoundCardsAsItems()

      # Try to read already stored values
      current_sound_card = Ops.get_integer(Tv.current_card, "sound_card_no", -1)
      current_rb = :rb_yes

      Builtins.y2debug("current card: Tv::current_card: %1", Tv.current_card)
      if current_sound_card == nil || Builtins.size(sound_cards) == 0 ||
          Ops.get_boolean(Tv.current_card, "dvb", false) &&
            Ops.less_than(current_sound_card, 0)
        current_rb = :rb_no
      end
      # We used -1 to get known, that we did not set the sound_card_no yet...
      # Let's clean it up!
      if current_sound_card == nil || Ops.less_than(current_sound_card, 0)
        current_sound_card = 0
      end

      contents = HBox(
        HSpacing(1.5),
        VBox(
          VSpacing(1.2),
          # Label text:
          Left(
            HBox(
              Label(_("TV or Radio Card")),
              Label(Opt(:outputField), current_card_name)
            )
          ),
          VSpacing(0.7),
          # Frame label:
          Frame(
            _("Audio Output Connection to Sound Card"),
            HBox(
              HSpacing(0.5),
              VBox(
                VSpacing(0.2),
                RadioButtonGroup(
                  Id(:rb_group),
                  VBox(
                    Left(
                      RadioButton(
                        Id(:rb_no),
                        Opt(:notify),
                        # radio button label - tv card is not connected to any sound card
                        _("Not Connected"),
                        current_rb != :rb_yes
                      )
                    ),
                    Left(
                      RadioButton(
                        Id(:rb_yes),
                        Opt(:notify),
                        # radio button label - tv card is not connected to any sound card
                        _("Connected To"),
                        current_rb == :rb_yes
                      )
                    )
                  )
                ),
                VBox(
                  HBox(
                    HSpacing(3.0),
                    Table(
                      Id(:sound_card_table),
                      Header(
                        # Header of table with sound card list 1/2
                        _("Number"),
                        # Header of table with sound card list 2/2
                        _("Sound Card")
                      ),
                      sound_cards
                    )
                  ),
                  Right(
                    PushButton(
                      Id(:configure_button),
                      Opt(:key_F4),
                      # PushButton label:
                      _("&Configure Sound Cards...")
                    )
                  )
                ),
                VSpacing(0.2)
              ),
              HSpacing(0.5)
            )
          ),
          VSpacing(1.2)
        ),
        HSpacing(1.5)
      )

      Wizard.SetContentsButtons(
        caption,
        contents,
        AudioDialogHelp(),
        Label.BackButton,
        Ops.get_boolean(Tv.current_card, "dvb", false) ?
          Label.OKButton :
          Label.NextButton
      )

      # Select the previously selected card
      if current_rb == :rb_yes
        UI.ChangeWidget(Id(:sound_card_table), :CurrentItem, current_sound_card)
      end

      ret = nil
      begin
        current_rb2 = Convert.to_symbol(
          UI.QueryWidget(Id(:rb_group), :CurrentButton)
        )
        UI.ChangeWidget(Id(:sound_card_table), :Enabled, current_rb2 == :rb_yes)

        ret = tvUserInput

        # Configure a sound card
        if ret == :configure_button
          current_sound_card = Convert.to_integer(
            UI.QueryWidget(Id(:sound_card_table), :CurrentItem)
          )

          WFM.CallFunction("sound", [])

          # Reread the list of the cards
          sound_cards = SoundCardsAsItems()
          UI.ChangeWidget(Id(:sound_card_table), :Items, sound_cards)
          if Ops.greater_than(current_sound_card, Builtins.size(sound_cards))
            current_sound_card = 0
          end
          UI.ChangeWidget(
            Id(:sound_card_table),
            :CurrentItem,
            current_sound_card
          )
          if Ops.greater_than(Builtins.size(sound_cards), 0)
            UI.ChangeWidget(Id(:rb_group), :CurrentButton, :rb_yes)
          end
        end

        # Check for selected soundcard
        if ret == :next &&
            UI.QueryWidget(Id(:rb_group), :CurrentButton) == :rb_yes &&
            UI.QueryWidget(Id(:sound_card_table), :CurrentItem) == nil
          # For translators: The user chose [Next] but did not select a sound card
          Popup.Message(_("Select a sound card."))
          ret = nil
        end
      end while ret != :back && ret != :abort && ret != :next

      # Store the values to Tv::current_card
      if ret != :back && ret != :abort
        current_rb2 = Convert.to_symbol(
          UI.QueryWidget(Id(:rb_group), :CurrentButton)
        )
        sel_no = Convert.to_integer(
          UI.QueryWidget(Id(:sound_card_table), :CurrentItem)
        )

        if current_rb2 == :rb_yes && sel_no != nil && sel_no != -1
          Ops.set(Tv.current_card, "sound_card_no", sel_no)
        else
          Ops.set(Tv.current_card, "sound_card_no", nil)
        end
      end

      deep_copy(ret)
    end

    # Returns a list of TV stations as table items
    # @param [Hash] xawtvrc map with contents of xawtvrc config file
    # @return item list
    def GetStationsAsItems(xawtvrc)
      xawtvrc = deep_copy(xawtvrc)
      stations = []
      Builtins.foreach(
        Convert.convert(xawtvrc, :from => "map", :to => "map <string, map>")
      ) do |sect, cont|
        if sect != "defaults" && sect != "global"
          stations = Builtins.add(
            stations,
            Item(Id(sect), Ops.get_string(xawtvrc, [sect, "channel"], ""), sect)
          )
        end
      end
      deep_copy(stations)
    end

    # Popup with TV stations scan
    # @param [String] norm TV norm (PAL/NTSC/...)
    # @param [String] freq frequency table (eourope-west/us-cable/...)
    # @return [Array] [ new xawtv conf, new items for stations table ]
    def ChannelsScanPopup(norm, freq)
      UI.OpenDialog(
        Opt(:decorated),
        HBox(
          HSpacing(1.5),
          VSpacing(18),
          VBox(
            HSpacing(60),
            VSpacing(0.5),
            # Popup label (heading)
            Label(_("TV Channel Scan")),
            VSpacing(0.5),
            LogView(Id(:scantv), "", 10, 0),
            VSpacing(0.5),
            ButtonBox(
              PushButton(Id(:ok), Label.OKButton),
              PushButton(Id(:cancel), Label.CancelButton)
            ),
            VSpacing(0.5)
          ),
          HSpacing(1.5)
        )
      )
      UI.ChangeWidget(Id(:ok), :Enabled, false)

      # before scan, tv module has to be loaded (maybe TV is not configured yet)
      start = Tv.tv_tmp_start
      if start != ""
        # error message
        ErrorWithDetails(
          _("The kernel module for TV support could not be loaded."),
          start
        )
        UI.CloseDialog
        return nil
      end

      cardnum = Tv.current_card_no

      if cardnum == nil
        # the card hasn't been configured yet, compute the number
        config = Tv.Export
        configured = Ops.get_list(config, "cards", [])

        cardnum = 0

        Builtins.foreach(configured) do |c|
          if !Ops.get_boolean(c, "dvb", false) &&
              !Ops.get_boolean(c, "radio", false)
            cardnum = Ops.add(cardnum, 1)
          end
        end
      end

      Builtins.y2milestone("Scanning TV card number %1", cardnum)

      SCR.Execute(
        path(".background.run_output"),
        Builtins.sformat(
          "/usr/bin/scantv -n %1 -f %2 2>&1 -o %3/xawtvrc -c /dev/video%4 -C /dev/vbi%4",
          norm,
          freq,
          Tv.tmpdir,
          cardnum
        )
      )

      test_output = ""
      ret = nil
      stations = []
      xawtvrc = {}
      retlist = nil
      # label (with the meaning: there is no station for this channel)
      # Keep it short! It is only note after channel + frequency data.
      # Example of the output strings:
      # E2   ( 48.25 MHz): no station
      # E3   ( 55.25 MHz): no station etc.
      nostation = _("No station")
      begin
        ret = UI.PollInput
        if Convert.to_boolean(SCR.Read(path(".background.output_open"))) &&
            Ops.greater_than(
              Convert.to_integer(SCR.Read(path(".background.newlines"))),
              0
            )
          newout = Convert.convert(
            SCR.Read(path(".background.newout")),
            :from => "any",
            :to   => "list <string>"
          )
          # read the output line from scantv
          test_output = Ops.get(newout, 0)
          if test_output != nil
            if Builtins.issubstring(test_output, "no station")
              test_output = Builtins.regexpsub(
                test_output,
                "(.*)no station(.*)",
                Builtins.sformat("\\1%1\\2", nostation)
              )
            end
            UI.ChangeWidget(Id(:scantv), :LastLine, Ops.add(test_output, "\n"))
          end
        elsif !Convert.to_boolean(SCR.Read(path(".background.output_open")))
          ret = :done
        end
      end while ret == nil

      SCR.Execute(path(".background.kill"), {})

      if ret == :done
        UI.ChangeWidget(Id(:ok), :Enabled, true)
        xawtvrc = Tv.ReadStationsConfig(path(".tmp.xawtvrc"))
        stations = GetStationsAsItems(xawtvrc)
        retlist = [xawtvrc, stations]
        UI.ChangeWidget(
          Id(:scantv),
          :LastLine,
          # label: summary of scanning for stations
          Builtins.sformat(
            _("Number of TV Stations Found: %1"),
            Builtins.size(stations)
          )
        )

        ret = UI.UserInput
      end
      UI.CloseDialog

      # TODO unload the modules?
      deep_copy(retlist)
    end

    # Popup for adding/editing TV station
    # @param [String] channel current channel (empty when adding)
    # @param [String] station current station name (empty when adding)
    # @param [Array] items list of current stations (to check duplicates)
    def StationPopup(channel, station, items)
      items = deep_copy(items)
      UI.OpenDialog(
        Opt(:decorated),
        HBox(
          HSpacing(1),
          VBox(
            HSpacing(50),
            VSpacing(0.5),
            HBox(
              # textentry label
              TextEntry(Id(:channel), _("&Channel"), channel),
              HSpacing(0.5),
              # textentry label
              TextEntry(Id(:station), _("Station &Name"), station)
            ),
            VSpacing(0.5),
            ButtonBox(
              PushButton(Id(:ok), Opt(:default), Label.OKButton),
              PushButton(Id(:cancel), Label.CancelButton)
            ),
            VSpacing(0.5)
          ),
          HSpacing(1)
        )
      )
      result = nil
      ret = nil
      UI.SetFocus(Id(:channel))
      while true
        result = UI.UserInput
        break if result == :cancel
        if result == :ok
          new_channel = Convert.to_string(UI.QueryWidget(Id(:channel), :Value))
          new_station = Convert.to_string(UI.QueryWidget(Id(:station), :Value))
          if new_channel == ""
            # message popup
            Popup.Message(_("Enter a TV channel."))
            UI.SetFocus(Id(:channel))
            next
          end
          if new_station == ""
            # message popup
            Popup.Message(_("Enter a station name."))
            UI.SetFocus(Id(:station))
            next
          end
          msg = ""
          Builtins.foreach(
            Convert.convert(items, :from => "list", :to => "list <term>")
          ) do |it|
            if Ops.get_string(it, 1, "") == new_channel &&
                new_channel != channel
              # error message
              msg = _("This channel already exists in the table.")
            end
            if Ops.get_string(it, 2, "") == new_station &&
                new_station != station
              # error message
              msg = _("This station name already exists in the table.")
            end
          end
          if msg != ""
            Popup.Message(msg)
            next
          end
          if channel != new_channel || station != new_station
            ret = Item(Id(new_station), new_channel, new_station)
          end
          break
        end
      end
      UI.CloseDialog
      deep_copy(ret)
    end


    # Detect the TV norms supported by the card (see bug #231147)
    # @param list of default norm items (for combobox)
    # @return updated item list
    def DetectTVNorms(norms_items)
      norms_items = deep_copy(norms_items)
      ret = []
      # busy popup
      Popup.ShowFeedback("", _("Detecting supported TV norms..."))

      # before scan, tv module has to be loaded (maybe TV is not configured yet)
      start = Tv.tv_tmp_start
      if start != ""
        Popup.ClearFeedback
        # error message
        ErrorWithDetails(
          _("The kernel module for TV support could not be loaded."),
          start
        )
        UI.CloseDialog
        return []
      end

      norm_labels = Builtins.listmap(
        Convert.convert(norms_items, :from => "list", :to => "list <term>")
      ) do |it|
        norm = Ops.get_string(it, [0, 0], "")
        { norm => Ops.get_string(it, 1, norm) }
      end

      cardnum = Tv.current_card_no
      if cardnum == nil
        # the card hasn't been configured yet, compute the number
        config = Tv.Export
        configured = Ops.get_list(config, "cards", [])

        cardnum = 0

        Builtins.foreach(configured) do |c|
          if !Ops.get_boolean(c, "dvb", false) &&
              !Ops.get_boolean(c, "radio", false)
            cardnum = Ops.add(cardnum, 1)
          end
        end
      end

      out = Convert.to_map(
        SCR.Execute(
          path(".target.bash_output"),
          Builtins.sformat(
            "/usr/bin/v4lctl -c /dev/video%1 list 2>/dev/null | grep norm",
            cardnum
          )
        )
      )
      stdout = Ops.get_string(out, "stdout", "")
      if stdout != ""
        l = Builtins.splitstring(Builtins.deletechars(stdout, "\n"), "|")
        if Ops.greater_than(Builtins.size(l), 4)
          curr = String.CutBlanks(Ops.get_string(l, 2, ""))
          _def = String.CutBlanks(Ops.get_string(l, 3, ""))
          norms = Builtins.filter(
            Builtins.splitstring(Ops.get_string(l, 4, ""), " \t")
          ) { |e| e != "" }
          _def = curr if Builtins.contains(norms, curr)
          Builtins.foreach(
            Convert.convert(norms, :from => "list", :to => "list <string>")
          ) do |norm|
            norm = Builtins.toupper(norm)
            ret = Builtins.add(
              ret,
              Item(
                Id(norm),
                Ops.get_string(norm_labels, norm, norm),
                norm == Builtins.toupper(_def)
              )
            )
          end
        end
      end
      Popup.ClearFeedback
      deep_copy(ret)
    end

    # Dialogs for TV stations management
    def ChannelsDialog
      # skip this dialog for DVB cards
      # TODO: station set up is different for DVB cards (use dvbscan utility)
      return :next if Ops.get_boolean(Tv.current_card, "dvb", false) == true

      # dialog caption for TV Stations Dialog
      caption = _("TV Station Configuration")

      norms = [
        # TV norm
        Item(Id("PAL"), _("PAL")),
        # TV norm
        Item(Id("NTSC"), _("NTSC")),
        # TV norm
        Item(Id("SECAM"), _("SECAM")),
        # TV norm
        Item(Id("PAL-NC"), _("PAL-NC")),
        # TV norm
        Item(Id("PAL-N"), _("PAL-N")),
        # TV norm
        Item(Id("PAL-M"), _("PAL-M")),
        # TV norm
        Item(Id("NTSC-JP"), _("NTSC-JP"))
      ]
      freqs_items = [
        # Tv frequency table
        Item(Id("us-bcast"), _("us-bcast")),
        # Tv frequency table
        Item(Id("us-cable"), _("us-cable")),
        # Tv frequency table
        Item(Id("us-cable-hrc"), _("us-cable-hrc")),
        # Tv frequency table
        Item(Id("japan-bcast"), _("japan-bcast")),
        # Tv frequency table
        Item(Id("japan-cable"), _("japan-cable")),
        # Tv frequency table
        Item(Id("europe-west"), _("europe-west")),
        # Tv frequency table
        Item(Id("europe-east"), _("europe-east")),
        # Tv frequency table
        Item(Id("italy"), _("italy")),
        # Tv frequency table
        Item(Id("newzealand"), _("newzealand")),
        # Tv frequency table
        Item(Id("australia"), _("australia")),
        # Tv frequency table
        Item(Id("ireland"), _("ireland")),
        # Tv frequency table
        Item(Id("france"), _("france")),
        # Tv frequency table
        Item(Id("china-bcast"), _("china-bcast")),
        # Tv frequency table
        Item(Id("southafrica"), _("southafrica")),
        # Tv frequency table
        Item(Id("argentina"), _("argentina")),
        # Tv frequency table
        Item(Id("australia-optus"), _("australia-optus")),
        # Tv frequency table
        Item(Id("russia"), _("russia"))
      ]

      channels_config = deep_copy(Tv.channels_config)
      tv_channels = GetStationsAsItems(channels_config)
      modified = false

      # TODO propose freq table from locale...
      contents = HBox(
        HSpacing(3),
        VBox(
          VSpacing(2),
          HBox(
            # combobox label for values like NTSC and PAL
            ComboBox(Id(:norms), _("&TV Standard"), norms),
            # combobox label
            ComboBox(Id(:freq), _("&Frequency Table"), freqs_items),
            HStretch(),
            VBox(
              Label(""),
              # button label
              PushButton(Id(:scan), _("&Scan the Channels"))
            )
          ),
          VSpacing(0.5),
          # frame label
          Frame(
            _("TV Stations"),
            HBox(
              HSpacing(0.5),
              VBox(
                Table(
                  Id(:channels),
                  Opt(:notify),
                  Header(
                    # table header 1/2
                    _("Channel"),
                    # table header 2/2
                    _("Station Name")
                  ),
                  tv_channels
                ),
                HBox(
                  PushButton(Id(:add), Opt(:key_F3), Label.AddButton),
                  PushButton(Id(:edit), Opt(:key_F4), Label.EditButton),
                  PushButton(Id(:del), Opt(:key_F5), Label.DeleteButton),
                  HStretch()
                )
              ),
              HSpacing(0.5)
            )
          ),
          VSpacing(2)
        ),
        HSpacing(3)
      )

      Wizard.SetContentsButtons(
        caption,
        contents,
        ChannelsDialogHelp(),
        # TODO Next for detected sequence...
        Label.BackButton,
        Label.OKButton
      )

      # detect the norm list supported by card
      detected_norms = DetectTVNorms(norms)
      if detected_norms != []
        UI.ChangeWidget(Id(:norms), :Items, detected_norms)
      end

      # set the starting configuation
      tv_norm = Builtins.toupper(
        Ops.get_string(channels_config, ["defaults", "norm"], "")
      )
      tv_freqtab = Ops.get_string(
        channels_config,
        ["global", "freqtab"],
        "europe-west"
      )
      if tv_norm != ""
        UI.ChangeWidget(Id(:norms), :Value, tv_norm)
      elsif detected_norms == []
        tv_norm = "PAL"
      end

      UI.ChangeWidget(Id(:freq), :Value, tv_freqtab)

      new_config = {}
      ret = nil
      begin
        ret = Convert.to_symbol(tvUserInput)
        tv_norm = Convert.to_string(UI.QueryWidget(Id(:norms), :Value))
        tv_freqtab = Convert.to_string(UI.QueryWidget(Id(:freq), :Value))

        if ret == :scan &&
            Package.InstallMsg(
              "v4l-tools",
              # popup label (install required application?)
              _(
                "To scan the TV channels, package '%1' is required.\nInstall it now?"
              )
            )
          scanned = ChannelsScanPopup(tv_norm, tv_freqtab)
          if scanned != nil
            new_config = Builtins.eval(Ops.get_map(scanned, 0, {}))
            tv_channels = Builtins.eval(Ops.get_list(scanned, 1, []))
            UI.ChangeWidget(Id(:channels), :Items, tv_channels)
            modified = true
          end
        end
        current = Convert.to_string(UI.QueryWidget(Id(:channels), :CurrentItem))
        if ret == :del && current != nil
          tv_channels = Builtins.filter(
            Convert.convert(tv_channels, :from => "list", :to => "list <term>")
          ) { |it| Ops.get_string(it, 2, "") != current }
          UI.ChangeWidget(Id(:channels), :Items, tv_channels)
          modified = true
        end
        if ret == :add
          new = StationPopup("", "", tv_channels)
          if new != nil
            tv_channels = Builtins.add(tv_channels, new)
            UI.ChangeWidget(Id(:channels), :Items, tv_channels)
            UI.ChangeWidget(Id(:channels), :CurrentItem, Ops.get(new, 2))
            modified = true
          end
        end
        if (ret == :edit || ret == :channels) && current != nil
          it = Convert.to_term(
            UI.QueryWidget(Id(:channels), term(:Item, current))
          )
          new = StationPopup(Ops.get_string(it, 1, ""), current, tv_channels)
          if new != nil
            tv_channels = Builtins.filter(
              Convert.convert(
                tv_channels,
                :from => "list",
                :to   => "list <term>"
              )
            ) { |i| Ops.get_string(i, 2, "") != current }
            tv_channels = Builtins.add(tv_channels, new)
            UI.ChangeWidget(Id(:channels), :Items, tv_channels)
            UI.ChangeWidget(Id(:channels), :CurrentItem, Ops.get(new, 2))
            modified = true
          end
        end
      end while !Builtins.contains([:back, :abort, :cancel, :next, :ok], ret)

      if tv_norm != Ops.get_string(channels_config, ["defaults", "norm"], "") ||
          tv_freqtab !=
            Ops.get_string(channels_config, ["global", "freqtab"], "")
        modified = true
      end

      if ret == :next && modified
        # save configuration to global values
        # channels_config["defaults","norm"] = tv_norm;
        # channels_config["global","freqtab"] = tv_freqtab;

        # use updated configuration after scan:
        Ops.set(
          channels_config,
          "defaults",
          Builtins.union(
            Ops.get_map(channels_config, "defaults", {}),
            Ops.get_map(new_config, "defaults", {})
          )
        )
        Ops.set(
          channels_config,
          "global",
          Builtins.union(
            Ops.get_map(channels_config, "global", {}),
            Ops.get_map(new_config, "global", {})
          )
        )

        # save channels
        xawtvrc = {
          "defaults" => Ops.get_map(channels_config, "defaults", {}),
          "global"   => Ops.get_map(channels_config, "global", {})
        }
        Builtins.foreach(
          Convert.convert(tv_channels, :from => "list", :to => "list <term>")
        ) do |i|
          name = Ops.get_string(i, 2, "")
          # preserve station settings that yast doesn't configure
          station = Builtins.eval(Ops.get_map(channels_config, name, {}))
          Ops.set(station, "channel", Ops.get_string(i, 1, ""))
          xawtvrc = Builtins.add(xawtvrc, name, station)
        end
        Tv.channels_config = Builtins.eval(xawtvrc)
        Tv.stations_modified = modified
      end
      ret
    end


    # Main workflow of the tv configuration
    # @return Sequence result of WizardSequencer().
    def MainSequence
      aliases = {
        "hardware"        => lambda { HardwareDialog() },
        "man_manual"      => lambda { ManualDialog(false) },
        "man_manual_warn" => lambda { ManualDialog(true) },
        "man_details0"    => lambda { ManualDetailsDialog(true, 0) },
        "man_details1"    => lambda { ManualDetailsDialog(true, 1) },
        "man_audio"       => lambda { AudioDialog() },
        "man_irc"         => lambda { IRCDialog(false) },
        "man_doit"        => lambda { CardAddCurrentWrapper() },
        "man_channels"    => lambda { ChannelsDialog() },
        "det_check"       => [lambda { CheckManualConfig() }, true],
        "det_details0"    => lambda { ManualDetailsDialog(true, 0) },
        "det_details1"    => lambda { ManualDetailsDialog(true, 1) },
        "det_audio"       => lambda { AudioDialog() },
        "det_irc"         => lambda { IRCDialog(false) },
        "det_channels"    => lambda { ChannelsDialog() },
        "det_doit"        => lambda { CardAddCurrentWrapper() },
        "add_manual"      => lambda { ManualDialog(false) },
        "add_details0"    => lambda { ManualDetailsDialog(true, 0) },
        "add_details1"    => lambda { ManualDetailsDialog(true, 1) },
        "add_audio"       => lambda { AudioDialog() },
        "add_irc"         => lambda { IRCDialog(false) },
        "add_doit"        => lambda { CardAddCurrentWrapper() },
        "add_channels"    => lambda { ChannelsDialog() },
        "rep_manual"      => lambda { ManualDialog(false) },
        "rep_details0"    => lambda { ManualDetailsDialog(false, 0) },
        "rep_details1"    => lambda { ManualDetailsDialog(false, 1) },
        "rep_audio"       => lambda { AudioDialog() },
        "rep_irc"         => lambda { IRCDialog(false) },
        "rep_doit"        => lambda { CardReplaceWithCurrentWrapper() },
        "rep_channels"    => lambda { ChannelsDialog() }
      }

      sequence = {
        "ws_start"        => "hardware",
        "hardware" =>
          #	    `edit_button      : "overview"
          {
            :abort             => :abort,
            :next              => :next,
            :add_manually      => "man_manual",
            :add_manually_warn => "man_manual_warn",
            :add_detected      => "det_check",
            :edit              => "rep_manual",
            :edit_button_radio => "rep_details0"
          },
        # "overview" :
        # 	$[
        # 	    `abort            : `abort,
        # 	    `next             : `next,
        # 	    `add_button       : "add_manual",
        # 	    `edit_button      : "rep_manual",
        # 	    `edit_button_radio: "rep_details0",
        # 	],
        "man_manual"      => {
          :abort          => :abort,
          :details_button => "man_details0",
          :next           => "man_audio",
          :channels       => "man_channels"
        },
        "man_channels"    => { :abort => :abort, :next => "man_manual" },
        "man_manual_warn" => {
          :abort          => :abort,
          :details_button => "man_details0",
          :next           => "man_audio",
          :channels       => "man_channels"
        },
        "man_details0"    => {
          :abort    => :abort,
          :details1 => "man_details1",
          :next     => "man_audio"
        },
        "man_details1"    => { :abort => :abort, :next => "man_audio" },
        "man_audio"       => { :abort => :abort, :next => "man_irc" },
        "man_irc"         => { :abort => :abort, :next => "man_doit" },
        "man_doit"        => { :next => "hardware" },
        "det_check"       => {
          :audio  => "det_audio",
          :manual => "det_details0"
        },
        "det_details0"    => {
          :abort    => :abort,
          :details1 => "det_details1",
          :next     => "det_audio"
        },
        "det_details1"    => { :abort => :abort, :next => "det_audio" },
        "det_audio"       => { :abort => :abort, :next => "det_irc" },
        "det_irc"         => { :abort => :abort, :next => "det_channels" },
        "det_channels"    => { :abort => :abort, :next => "det_doit" },
        "det_doit"        => { :next => "hardware" },
        "add_manual"      => {
          :abort          => :abort,
          :details_button => "add_details0",
          :next           => "add_audio",
          :channels       => "add_channels"
        },
        "add_channels"    => { :abort => :abort, :next => "add_manual" },
        "add_details0"    => {
          :abort    => :abort,
          :details1 => "add_details1",
          :next     => "add_audio"
        },
        "add_details1"    => { :abort => :abort, :next => "add_audio" },
        "add_audio"       => { :abort => :abort, :next => "add_irc" },
        "add_irc"         => { :abort => :abort, :next => "add_doit" },
        "add_doit"        => { :next => "hardware" },
        "rep_manual"      => {
          :abort          => :abort,
          :details_button => "rep_details0",
          :next           => "rep_audio",
          :channels       => "rep_channels"
        },
        "rep_channels"    => { :abort => :abort, :next => "rep_manual" },
        "rep_details0"    => {
          :abort    => :abort,
          :details1 => "rep_details1",
          :next     => "rep_audio"
        },
        "rep_details1"    => { :abort => :abort, :next => "rep_audio" },
        "rep_audio"       => { :abort => :abort, :next => "rep_irc" },
        "rep_irc"         => { :abort => :abort, :next => "rep_doit" },
        "rep_doit"        => { :next => "hardware" }
      }
      # FIXME: better sequences with irc, channels

      ret = Sequencer.Run(aliases, sequence)

      deep_copy(ret)
    end


    # Whole configuration of tv
    # @return Sequence result of WizardSequencer().
    def TvSequence
      aliases = {
        "read"  => [lambda { ReadDialog() }, true],
        "main"  => lambda { MainSequence() },
        "write" => [lambda { WriteDialog() }, true]
      }

      sequence = {
        "ws_start" => "read",
        "read"     => { :abort => :abort, :next => "main" },
        "main"     => { :abort => :abort, :next => "write" },
        "write"    => { :abort => :abort, :next => :next }
      }

      Wizard.CreateDialog
      Wizard.SetDesktopTitleAndIcon("tv")
      ret = Sequencer.Run(aliases, sequence)
      UI.CloseDialog

      deep_copy(ret)
    end

    # Whole configuration of TV without reading and writing.
    # It is needed for the proposal stuff.
    # @return Sequence result of MainSequence().
    def TvSequenceNoIO
      #Header of TV Initialization Dialog
      caption = _("Initializing TV and Radio Card Configuration")
      contents = Label(_("Initializing..."))

      Wizard.CreateDialog
      Wizard.SetContentsButtons(
        caption,
        contents,
        "",
        Label.BackButton,
        Label.NextButton
      )

      ret = MainSequence()

      UI.CloseDialog
      deep_copy(ret)
    end
  end
end

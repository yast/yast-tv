# encoding: utf-8

# File:
# Package:	TV cards configuration
# Summary:	User interface functions.
# Authors:	Jiri Suchomel <jsuchome@novell.com>
#
# $Id$
#
module Yast
  module TvIrcUiInclude
    def initialize_tv_irc_ui(include_target)
      Yast.import "UI"

      textdomain "tv"

      Yast.import "Label"
      Yast.import "Popup"
      Yast.import "Package"
      Yast.import "Service"
      Yast.import "Tv"
      Yast.import "Wizard"
      Yast.import "UIHelper"
      Yast.import "Message"
      Yast.import "Report"

      Yast.include include_target, "tv/helps.rb"
      Yast.include include_target, "tv/misc.rb"
    end

    # Dialog for testing IRC
    # @return [Boolean] false when Abort was pressed or some problems occured
    def IRCTestPopup(config_file, mod, modified)
      orig_module = ""
      orig_config = ""
      orig_start = false

      # internal function
      # start with temporary LIRC configuration to enable the test
      # @return empty string on success, error message otherwise
      lirc_tmp_start = lambda do
        return {} if !modified
        # store old configuration
        orig_module = Convert.to_string(
          SCR.Read(path(".sysconfig.lirc.LIRC_MODULE"))
        )
        if SCR.Read(path(".target.size"), "/etc/lircd.conf") != -1
          orig_config = Ops.add(Tv.tmpdir, "/lircd.conf")
          SCR.Execute(
            path(".target.bash"),
            Ops.add("/bin/cp /etc/lircd.conf ", orig_config)
          )
          Builtins.y2milestone("copy /etc/lirc.conf to %1", orig_config)
        end
        # 1. copy new config file, update sysconfig value

        SCR.Write(path(".sysconfig.lirc.LIRC_MODULE"), mod)
        SCR.Write(path(".sysconfig.lirc"), nil)

        if config_file != "/etc/lircd.conf"
          SCR.Execute(
            path(".target.bash"),
            Builtins.sformat("/bin/cp %1 /etc/lircd.conf", config_file)
          )
        end

        # 2. start service (what if it is running?)
        orig_start = Service.Status("lirc") == 0

        out = {}
        #when module cannot be loaded, Runlevel returns 0 -> use target.bash
        if orig_start
          out = Convert.to_map(
            SCR.Execute(path(".target.bash_output"), "rclirc restart")
          )
        else
          out = Convert.to_map(
            SCR.Execute(path(".target.bash_output"), "rclirc start")
          )
        end
        deep_copy(out)
      end

      # internal function
      # return LIRC configuration to original state after testing
      lirc_tmp_stop = lambda do
        return true if !modified
        if orig_config != ""
          Builtins.y2milestone("copy %1 to /etc", orig_config)
          SCR.Execute(
            path(".target.bash"),
            Builtins.sformat("/bin/cp %1 /etc/lircd.conf ", orig_config)
          )
        end
        SCR.Write(path(".sysconfig.lirc.LIRC_MODULE"), orig_module)
        SCR.Write(path(".sysconfig.lirc"), nil)
        if orig_start
          Service.RunInitScript("lirc", "restart")
        else
          Service.RunInitScript("lirc", "stop")
        end
        true
      end

      UI.OpenDialog(Label(_("Initializing...")))

      start = lirc_tmp_start.call
      if Ops.get_integer(start, "exit", -1) != 0
        # error popup text
        ErrorWithDetails(
          _("Starting the 'lirc' service failed."),
          Ops.add(
            Ops.add(
              Ops.add(
                _("Output from /etc/init.d/lirc command:\n\n"),
                Ops.get_string(start, "stdout", "")
              ),
              "\n"
            ),
            Ops.get_string(start, "stderr", "")
          )
        )
        UI.CloseDialog
        lirc_tmp_stop.call
        return false
      end

      # test if IRC device is present
      # FIXME device is created dynamically
      # if (SCR::Execute(.target.bash, "echo 2>/dev/null < /dev/lirc") != 0)
      # {
      # 	// error popup text
      # 	Popup::Error (_("No IRC device is present.
      # (Maybe wrong module was loaded.)"));
      # 	UI::CloseDialog();
      # 	lirc_tmp_stop ();
      # 	return false;
      # }

      # 3. run irw -> test
      SCR.Execute(path(".background.run_output"), "/usr/bin/irw")

      UI.CloseDialog
      # construct the dialog
      UI.OpenDialog(
        Opt(:decorated),
        HBox(
          HSpacing(1.5),
          VSpacing(18),
          VBox(
            HSpacing(60),
            VSpacing(0.5),
            # Popup label (heading)
            Label(_("IRC Test")),
            # Popup label (info text)
            Label(
              _(
                "Push the buttons of your IR controller to test its functionality."
              )
            ),
            VSpacing(0.5),
            LogView(Id(:irw), "", 10, 0),
            VSpacing(0.5),
            PushButton(Id(:done), Opt(:default), Label.OKButton),
            VSpacing(0.5)
          ),
          HSpacing(1.5)
        )
      )

      # read the irw output
      test_output = ""
      ret = nil
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
          # read the output line from irw:
          test_output = Ops.get(newout, 0)
          if test_output != nil
            UI.ChangeWidget(Id(:irw), :LastLine, Ops.add(test_output, "\n"))
          end
        elsif !Convert.to_boolean(SCR.Read(path(".background.output_open")))
          # error text
          Popup.Error(_("The testing application is not responding."))
          ret = :ok
        end
      end while ret == nil

      SCR.Execute(path(".background.kill"), nil)
      lirc_tmp_stop.call
      UI.CloseDialog

      true
    end


    # Dialog for seting up IRC
    # @param run from irc.ycp client? (=not from tv module)
    def IRCDialog(alone)
      # skip IRC dialgo for DVB cards
      # TODO: skip for all DVB cards?
      if alone == false &&
          Ops.get_boolean(Tv.current_card, "dvb", false) == true
        return :next
      end

      # For translators: Caption of the dialog
      caption = _("Infrared Control Configuration")

      use_irc = Tv.use_irc
      irc_config = Tv.irc_config
      irc_module = Tv.irc_module
      mods = deep_copy(Tv.irc_modules_list)

      irc_module = Tv.GetIRCModule if irc_module == ""
      # FIXME irc_module should be loaded when new TV card is chosen...

      return :next if !alone && Ops.get_boolean(Tv.current_card, "radio", false)

      # string startdir = "/usr/share/lirc/remotes/";
      # list remotes_items = [];
      # foreach (string control, (list<string>) Tv::remotes, ``{
      # 	list aslist = splitstring (control, "/");
      # 	string last = aslist [ size(aslist)-1 ]:"";
      # 	if (issubstring (last, "lircd.conf."))
      # 	    last = substring (last, size ("lircd.conf."));
      # 	if (last != "")
      # 	    remotes_items = add (remotes_items, `item(`id(control), last));
      # });
      #
      # if (irc_config == "/etc/lircd.conf")
      # 	remotes_items = add (remotes_items,
      # 	    `item(`id("/etc/lircd.conf"), _("current (/etc/lircd.conf)")));

      con = HBox(
        HSpacing(3),
        VBox(
          VSpacing(2),
          RadioButtonGroup(
            Id(:rd),
            Left(
              HVSquash(
                VBox(
                  Left(
                    RadioButton(
                      Id(:no),
                      Opt(:notify),
                      # radio button label
                      _("Do No&t Use IRC"),
                      !use_irc
                    )
                  ),
                  Left(
                    RadioButton(
                      Id(:yes),
                      Opt(:notify),
                      # radio button label
                      _("&Use IRC"),
                      use_irc
                    )
                  )
                )
              )
            )
          ),
          VSpacing(0.5),
          # frame label
          Frame(
            _("IRC Settings"),
            HBox(
              HSpacing(),
              VBox(
                VSpacing(),
                # `ReplacePoint (`id(`configs),
                # `HBox(
                #     // combobox label
                #     `ComboBox(`id(`config), `opt(`hstretch),
                # 	_("IRC Config File"), remotes_items),
                #     `VBox(
                # 	`Label (""),
                # 	// button label
                # 	`PushButton(`id(`brow),`opt(`key_F7), _("M&ore..."))
                #     )
                # )),
                ComboBox(
                  Id(:mods),
                  Opt(:notify, :hstretch),
                  # combobox label
                  _("&Kernel Module"),
                  mods
                ),
                Left(
                  CheckBox(
                    Id(:desc_ch),
                    Opt(:notify),
                    #checkbox label
                    _("Show Module &Description"),
                    false
                  )
                ),
                ReplacePoint(Id(:rp), Empty()),
                VSpacing(0.5),
                Right(
                  # button label
                  PushButton(Id(:test), Opt(:key_F6), _("&Test"))
                ),
                VSpacing(0.5)
              ),
              HSpacing()
            )
          ),
          VStretch()
        ),
        HSpacing(3)
      )


      Wizard.SetContentsButtons(
        caption,
        con,
        IRCDialogHelp(),
        Label.BackButton,
        alone ? Label.FinishButton : Label.NextButton
      )


      Builtins.foreach([:mods, :test, :desc_ch]) do |widget|
        UI.ChangeWidget(Id(widget), :Enabled, use_irc)
      end

      #    UI::ChangeWidget (`id(`config), `Value, irc_config);

      if Builtins.contains(mods, irc_module)
        UI.ChangeWidget(Id(:mods), :Value, irc_module)
      end

      ret = nil
      begin
        ret = Convert.to_symbol(tvUserInput)

        #	irc_config = (string) UI::QueryWidget (`id(`config),  `Value);

        if irc_module != Convert.to_string(UI.QueryWidget(Id(:mods), :Value))
          irc_module = Convert.to_string(UI.QueryWidget(Id(:mods), :Value))
          if Convert.to_boolean(UI.QueryWidget(Id(:desc_ch), :Value))
            UI.ChangeWidget(
              Id(:desc),
              :Value,
              Ops.get_string(Tv.irc_modules, irc_module, "")
            )
          end
        end
        if ret == :desc_ch
          if Convert.to_boolean(UI.QueryWidget(Id(:desc_ch), :Value))
            if Tv.irc_modules == {}
              UI.OpenDialog(
                UIHelper.SpacingAround(
                  # busy popup text (waiting for other action):
                  Label(
                    _("Retrieving list\nof kernel module descriptions...\n")
                  ),
                  1.5,
                  1.5,
                  0.5,
                  0.5
                )
              )
              Tv.LoadIRCModulesDescription
              UI.CloseDialog
            end
            UI.ReplaceWidget(
              Id(:rp),
              VSquash(
                HBox(
                  VSpacing(3),
                  RichText(
                    Id(:desc),
                    Opt(:shrinkable),
                    Ops.get_string(Tv.irc_modules, irc_module, "")
                  )
                )
              )
            )
          else
            UI.ReplaceWidget(Id(:rp), Empty())
          end
        end

        if ret == :yes || ret == :no
          use_irc = ret == :yes
          if use_irc
            lirc_installed = Tv.lirc_installed

            if !lirc_installed && !Package.InstallAll(["lirc", "lirc-remotes"])
              Report.Error(Message.FailedToInstallPackages)

              use_irc = false
              UI.ChangeWidget(Id(:rd), :CurrentButton, :no)
            else
              if lirc_installed == false
                # the package has been just installed - make ini-agent reread the config file
                SCR.UnmountAgent(path(".sysconfig.lirc"))

                # read IRC settings
                Tv.ReadIRC
              end
            end
          end

          Builtins.foreach([:mods, :test, :desc_ch]) do |widget|
            UI.ChangeWidget(Id(widget), :Enabled, use_irc)
          end
        end
        # if (ret == `brow)
        # {
        #     string file = UI::AskForExistingFile (startdir, "*", "");
        #     if (file != nil)
        #     {
        # 	remotes_items = union (remotes_items, [`item(`id(file), file)]);
        # 	UI::ReplaceWidget (`id(`configs), `HBox(
        # 	    `ComboBox(`id(`config), `opt(`hstretch),
        # 		_("IRC Config File"), remotes_items),
        # 	    `VBox(`Label (""),
        # 		`PushButton(`id(`brow),`opt(`key_F7), _("Mo&re..."))))
        # 	);
        # 	UI::ChangeWidget (`id(`config), `Value, file);
        #     }
        #
        # }
        if ret == :test
          IRCTestPopup(
            irc_config,
            irc_module,
            use_irc != Tv.use_irc || irc_module != Tv.irc_module ||
              irc_config != Tv.irc_config
          )
        end
      end while !Builtins.contains([:back, :abort, :cancel, :next, :ok], ret)

      if ret == :next &&
          (use_irc != Tv.use_irc || irc_module != Tv.irc_module ||
            irc_config != Tv.irc_config)
        Tv.irc_modified = true
        Tv.use_irc = use_irc
        Tv.irc_module = irc_module
        Tv.irc_config = irc_config
      end
      ret
    end
  end
end

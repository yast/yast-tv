# encoding: utf-8

# File:	include/tv/misc.ycp
# Package:	TV cards configuration
# Summary:	Miscelanous functions for configuration of tv.
# Authors:	Jan Holesovsky <kendy@suse.cz>
#
# $Id$
#
# Functions that are not UI related, do not belong to modules/tv.ycp
# and are not common enough to be in a library.
module Yast
  module TvMiscInclude
    def initialize_tv_misc(include_target)
      Yast.import "UI"

      Yast.import "Sound"
      Yast.import "Tv"
      Yast.import "Label"
      Yast.import "Popup"

      textdomain "tv"

      # Force translation of "No tuner" string, it is in a generated file
      # which might be missing when generating .pot file
      # (see bnc#371289, esp. comment #6)
      @no_tuner = _("No tuner")

      # table item for all other card vendors (bnc#583240)
      @other_vendors = _("Other vendors")
      # unknown/generic card using 'bttv' driver
      @unknown_bttv_card = _("Unknown card (driver bttv)")
      # unknown/generic card using 'cx88xx' driver
      @unknown_cx88xx_card = _("Unknown card (driver cx88xx)")
      # unknown/generic card using 'saa7134' driver
      @unknown_saa7134_card = _("Unknown card (driver saa7134)") 
      # EOF
    end

    # Compares parameters of a card with the current_card. It is needed for
    # decision whether to select the card.
    # @param [Hash] parameters The 'parameters' which change
    # @param [Hash] parameters_to_compare The reference 'parameters' (the ones I am searching for)
    # @return [Boolean] Should I select the card with parameters 'parameters'?
    def CmpParameters(parameters, parameters_to_compare)
      parameters = deep_copy(parameters)
      parameters_to_compare = deep_copy(parameters_to_compare)
      select_this = true
      if Ops.greater_than(Builtins.size(parameters), 0)
        Builtins.foreach(
          Convert.convert(
            parameters,
            :from => "map",
            :to   => "map <string, any>"
          )
        ) do |param, value|
          select_this = false if value != Ops.get(parameters_to_compare, param)
        end
      else
        if Builtins.size(parameters) == 0 &&
            Builtins.size(parameters_to_compare) == 0
          select_this = true
        else
          select_this = false
        end
      end
      select_this
    end

    # List of the sound cards acceptable by the Table widget.
    # @return [Array] List of sound cards
    def SoundCardsAsItems
      Builtins.maplist(
        Convert.convert(
          Sound.GetSoundCardList,
          :from => "list",
          :to   => "list <map <string, any>>"
        )
      ) do |card|
        sound_card_no = Ops.get_integer(card, "card_no", -1)
        Item(
          Id(sound_card_no),
          Builtins.sformat("%1", sound_card_no),
          Ops.get_string(card, "name", "")
        )
      end
    end

    # Enhanced version of UserInput which asks if really abort after
    # pressing [Abort].
    # @return [Object] The value of the resulting UserInput.
    def tvUserInput
      ret = nil
      begin
        ret = UI.UserInput
      end while (ret == :cancel || ret == :abort) && !Popup.ReallyAbort(Tv.IsDirty)
      #	     (Tv::IsDirty()? !Popup::ReallyAbort (true): false));

      ret == :cancel ? :abort : ret
    end

    # Error popup with the possibility of showing additional information
    # about the problem
    # @param [String] error basic error message
    # @param [String] details more informations, e.g. stderr of some script
    def ErrorWithDetails(error, details)
      UI.OpenDialog(
        HBox(
          HSpacing(0.5),
          VBox(
            VSpacing(0.5),
            # label
            Left(Heading(Label.ErrorMsg)),
            Left(Label(error)),
            ReplacePoint(Id(:rp), Empty()),
            VSpacing(0.5),
            Left(
              CheckBox(
                Id(:details),
                Opt(:notify),
                # checkbox label
                _("&Show Details"),
                false
              )
            ),
            PushButton(Id(:ok), Opt(:key_F10, :default), Label.OKButton)
          ),
          HSpacing(0.5)
        )
      )
      ret = nil
      begin
        ret = Convert.to_symbol(UI.UserInput)
        if ret == :details
          if Convert.to_boolean(UI.QueryWidget(Id(:details), :Value))
            UI.ReplaceWidget(Id(:rp), Frame(_("Details"), Left(Label(details))))
          else
            UI.ReplaceWidget(Id(:rp), Empty())
          end
        end
      end while ret != :ok && ret != :cancel
      UI.CloseDialog

      nil
    end
  end
end

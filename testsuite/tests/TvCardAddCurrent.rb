# encoding: utf-8

module Yast
  class TvCardAddCurrentClient < Client
    def main
      # testedfiles: Tv.ycp
      Yast.include self, "testsuite.rb"

      @READ = { "target" => { "size" => -1, "tmpdir" => "/tmp" } }

      TESTSUITE_INIT([@READ], nil)
      Yast.import "Tv"

      # Tv::current_card == nil
      TEST_It_Now(nil)
      # Tv::current_card == $[]
      TEST_It_Now({})

      # Tv::current_card == something useful
      TEST_It_Now(
        {
          "module"        => "abc",
          "parameters"    => { "par_par" => "val_val" },
          "unique_key"    => "abc.uniq_key",
          "sound_card_no" => 5
        }
      )

      nil
    end

    def TEST_It_Now(curcard_totest)
      curcard_totest = deep_copy(curcard_totest)
      DUMP("-------------------------------------------")
      Tv.cards = nil
      Tv.current_card = deep_copy(curcard_totest)
      Tv.CardAddCurrent
      DUMP(Tv.cards)

      # Tv::cards == $[]
      Tv.cards = []
      Tv.current_card = deep_copy(curcard_totest)
      Tv.CardAddCurrent
      DUMP(Tv.cards)

      # Tv::cards == card1
      Tv.cards = [
        {
          "module"        => "bttv",
          "parameters"    => { "param1" => "testvalue" },
          "unique_key"    => "hluk.HvsIesmXXX1",
          "sound_card_no" => 0
        }
      ]
      Tv.current_card = deep_copy(curcard_totest)
      Tv.CardAddCurrent
      DUMP(Tv.cards)

      # Tv::cards == card1, card2
      Tv.cards = [
        {
          "module"        => "bttv",
          "parameters"    => { "param1" => "testvalue" },
          "unique_key"    => "hluk.HvsIesmXXX1",
          "sound_card_no" => 0
        },
        {
          "module"        => "bttv",
          "parameters"    => { "par_other" => "testvalue2" },
          "unique_key"    => "j7F3.J8dhgs34fK2",
          "sound_card_no" => 1
        }
      ]
      Tv.current_card = deep_copy(curcard_totest)
      Tv.CardAddCurrent
      DUMP(Tv.cards)

      # Tv::cards == card1, nil, nil, card4
      Tv.cards = [
        {
          "module"        => "bttv",
          "parameters"    => { "param1" => "testvalue" },
          "unique_key"    => "hluk.HvsIesmXXX1",
          "sound_card_no" => 0
        },
        {},
        {},
        {
          "module"        => "xyz",
          "parameters"    => { "par_other" => "testvalue2" },
          "unique_key"    => "j7F3.J8dhgs34fK2",
          "sound_card_no" => 1
        }
      ]
      Tv.current_card = deep_copy(curcard_totest)
      Tv.CardAddCurrent
      DUMP(Tv.cards)

      nil
    end
  end
end

Yast::TvCardAddCurrentClient.new.main

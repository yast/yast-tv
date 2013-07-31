# encoding: utf-8

module Yast
  class TvCardReplaceWithCurrentClient < Client
    def main
      # testedfiles: Tv.ycp

      Yast.include self, "testsuite.rb"

      @READ = { "target" => { "size" => -1, "tmpdir" => "/tmp" } }

      TESTSUITE_INIT([@READ], nil)
      Yast.import "Tv"

      TEST_It_Now_CardNo(nil)

      TEST_It_Now_CardNo(-1)

      TEST_It_Now_CardNo(0)

      TEST_It_Now_CardNo(1)

      TEST_It_Now_CardNo(3)

      nil
    end

    def TEST_It_Now(curcard_totest, card_no_totest)
      curcard_totest = deep_copy(curcard_totest)
      # Tv::cards == nil
      Tv.cards = nil
      Tv.current_card = deep_copy(curcard_totest)
      Tv.CardReplaceWithCurrent(card_no_totest)
      DUMP(Tv.cards)

      # Tv::cards == []
      Tv.cards = []
      Tv.current_card = deep_copy(curcard_totest)
      Tv.CardReplaceWithCurrent(card_no_totest)
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
      Tv.CardReplaceWithCurrent(card_no_totest)
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
      Tv.CardReplaceWithCurrent(card_no_totest)
      DUMP(Tv.cards)

      # Tv::cards == card1, nil, nil, card4
      Tv.cards = [
        {
          "module"        => "bttv",
          "parameters"    => { "param1" => "testvalue" },
          "unique_key"    => "hluk.HvsIesmXXX1",
          "sound_card_no" => 0
        },
        nil,
        nil,
        {
          "module"        => "xyz",
          "parameters"    => { "par_other" => "testvalue2" },
          "unique_key"    => "j7F3.J8dhgs34fK2",
          "sound_card_no" => 1
        }
      ]
      Tv.current_card = deep_copy(curcard_totest)
      Tv.CardReplaceWithCurrent(card_no_totest)
      DUMP(Tv.cards)

      nil
    end

    def TEST_It_Now_CardNo(card_no_totest)
      # Tv::current_card == nil
      TEST_It_Now(nil, card_no_totest)

      # Tv::current_card == $[]
      TEST_It_Now({}, card_no_totest)

      # Tv::current_card == something useful
      TEST_It_Now(
        {
          "module"        => "abc",
          "parameters"    => { "par_par" => "val_val" },
          "unique_key"    => "abc.uniq_key",
          "sound_card_no" => 5
        },
        card_no_totest
      )

      nil
    end
  end
end

Yast::TvCardReplaceWithCurrentClient.new.main

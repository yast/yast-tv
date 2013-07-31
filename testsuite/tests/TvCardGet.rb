# encoding: utf-8

module Yast
  class TvCardGetClient < Client
    def main
      # testedfiles: Tv.ycp
      Yast.include self, "testsuite.rb"

      @READ = { "target" => { "size" => -1, "tmpdir" => "/tmp" } }

      TESTSUITE_INIT([@READ], nil)
      Yast.import "Tv"

      TEST_It_Now(nil)

      TEST_It_Now(-1)

      TEST_It_Now(0)

      TEST_It_Now(1)

      TEST_It_Now(3)

      nil
    end

    def TEST_It_Now(card_no_totest)
      # Tv::cards == nil
      Tv.cards = nil
      DUMP(Tv.CardGet(card_no_totest))

      # Tv::cards == []
      Tv.cards = []
      DUMP(Tv.CardGet(card_no_totest))

      # Tv::cards == card1
      Tv.cards = [
        {
          "module"        => "bttv",
          "parameters"    => { "param1" => "testvalue" },
          "unique_key"    => "hluk.HvsIesmXXX1",
          "sound_card_no" => 0
        }
      ]
      DUMP(Tv.CardGet(card_no_totest))

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
      DUMP(Tv.CardGet(card_no_totest))

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
      DUMP(Tv.CardGet(card_no_totest))

      nil
    end
  end
end

Yast::TvCardGetClient.new.main

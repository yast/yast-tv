# encoding: utf-8

module Yast
  class TvCardsUniqueKeysClient < Client
    def main
      # testedfiles: Tv.ycp

      Yast.include self, "testsuite.rb"

      @READ = { "target" => { "size" => -1, "tmpdir" => "/tmp" } }

      TESTSUITE_INIT([@READ], nil)
      Yast.import "Tv"

      # Tv::cards == nil
      Tv.cards = nil
      @keys = Tv.CardsUniqueKeys
      DUMP(@keys)

      # Tv::cards == $[]
      Tv.cards = []
      DUMP(@keys)

      # Tv::cards == card1
      Tv.cards = [
        {
          "module"        => "bttv",
          "parameters"    => { "param1" => "testvalue" },
          "unique_key"    => "hluk.HvsIesmXXX1",
          "sound_card_no" => 0
        }
      ]
      @keys = Tv.CardsUniqueKeys
      DUMP(@keys)

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
      @keys = Tv.CardsUniqueKeys
      DUMP(@keys)

      nil
    end
  end
end

Yast::TvCardsUniqueKeysClient.new.main

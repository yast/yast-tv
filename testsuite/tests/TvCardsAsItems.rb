# encoding: utf-8

module Yast
  class TvCardsAsItemsClient < Client
    def main
      # testedfiles: Tv.ycp

      Yast.include self, "testsuite.rb"

      @READ = { "target" => { "size" => -1, "tmpdir" => "/tmp" } }

      TESTSUITE_INIT([@READ], nil)
      Yast.import "Tv"

      # Tv::cards == nil
      Tv.cards = nil
      @items = Tv.CardsAsItems
      DUMP(@items)

      # Tv::cards == $[]
      Tv.cards = []
      @items = Tv.CardsAsItems
      DUMP(@items)

      # Tv::cards == card1
      Tv.cards = [
        {
          "module"        => "bttv",
          "parameters"    => { "param1" => "testvalue" },
          "unique_key"    => "hluk.HvsIesmXXX1",
          "sound_card_no" => 0
        }
      ]
      @items = Tv.CardsAsItems
      DUMP(@items)

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
          "name"          => "My TV_card",
          "unique_key"    => "j7F3.J8dhgs34fK2",
          "sound_card_no" => 1
        }
      ]
      @items = Tv.CardsAsItems
      DUMP(@items)

      nil
    end
  end
end

Yast::TvCardsAsItemsClient.new.main

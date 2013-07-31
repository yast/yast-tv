# encoding: utf-8

module Yast
  class TvDetectedCardsAsItemsClient < Client
    def main
      # testedfiles: Tv.ycp

      Yast.include self, "testsuite.rb"

      @READ = { "target" => { "size" => -1, "tmpdir" => "/tmp" } }

      TESTSUITE_INIT([@READ], nil)
      Yast.import "Tv"
      # testing with different values of detected_cards
      TEST_It_Now(nil)

      TEST_It_Now(
        [
          {
            "module"        => "bttv",
            "name"          => "First detected card",
            "unique_key"    => "hluk.HvsIesmXXX1",
            "sound_card_no" => 0
          }
        ]
      )

      TEST_It_Now(
        [
          {
            "module"     => "xyz",
            "name"       => "My TV_card",
            "unique_key" => "j7F3.J8dhgs34fK2"
          },
          {
            "module"        => "bttv",
            "name"          => "Some other detected card",
            "unique_key"    => "hluk.YYY2",
            "sound_card_no" => 0
          }
        ]
      )

      nil
    end

    def TEST_It_Now(detected)
      detected = deep_copy(detected)
      Tv.detected_cards = deep_copy(detected)
      DUMP("---------------")

      # Tv::cards (... already installed cards) == nil
      Tv.cards = nil
      detected_items = Tv.DetectedCardsAsItems
      DUMP(detected_items)

      # Tv::cards == $[]
      Tv.cards = []
      detected_items = Tv.DetectedCardsAsItems
      DUMP(detected_items)

      # Tv::cards == card1
      Tv.cards = [
        {
          "module"        => "bttv",
          "parameters"    => { "param1" => "testvalue" },
          "unique_key"    => "hluk.HvsIesmXXX1",
          "sound_card_no" => 0
        }
      ]
      detected_items = Tv.DetectedCardsAsItems
      DUMP(detected_items)

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
      detected_items = Tv.DetectedCardsAsItems
      DUMP(detected_items)

      nil
    end
  end
end

Yast::TvDetectedCardsAsItemsClient.new.main

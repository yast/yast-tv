# encoding: utf-8

module Yast
  class TvCardsDBVendorGetCardsClient < Client
    def main
      # testedfiles: Tv.ycp

      Yast.include self, "testsuite.rb"

      @READ = { "target" => { "size" => -1, "tmpdir" => "/tmp" } }

      TESTSUITE_INIT([@READ], nil)
      Yast.import "Tv"

      TEST_It_Now(nil, nil)

      TEST_It_Now(
        {
          "module"     => "bttv",
          "name"       => "my autodetected card",
          "unique_key" => "123xyz"
        },
        nil
      )

      # autodetected card has index 0
      TEST_It_Now({ "name" => "my autodetected card" }, 0)

      TEST_It_Now({ "name" => "my autodetected card" }, 1)

      TEST_It_Now(nil, 1)

      nil
    end

    def TEST_It_Now(auto, vendor)
      auto = deep_copy(auto)
      DUMP("---------------")

      # cards_database cannot be nil (see ReadCardsDatabase)
      Tv.cards_database = nil
      items = Tv.CardsDBVendorGetCards(auto, vendor)
      DUMP(items)

      Tv.cards_database = []
      items = Tv.CardsDBVendorGetCards(auto, vendor)
      DUMP(items)

      Tv.cards_database = [
        {
          "cards" => [
            {
              "module"     => "bttv",
              "name"       => "Unknown bttv card",
              "parameters" => { "card" => "0" }
            },
            {
              "module"     => "bttv",
              "name"       => "TView99 CPH06X",
              "parameters" => { "card" => "38" }
            }
          ],
          "name"  => "Other vendors"
        },
        {
          "cards" => [
            {
              "module"     => "bttv",
              "name"       => "ATI TV-Wonder VE",
              "parameters" => { "card" => "64" }
            }
          ],
          "name"  => "ATI"
        }
      ]
      items = Tv.CardsDBVendorGetCards(auto, vendor)
      DUMP(items)

      nil
    end
  end
end

Yast::TvCardsDBVendorGetCardsClient.new.main

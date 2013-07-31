# encoding: utf-8

module Yast
  class TvCardsDBVendorsAsItemsClient < Client
    def main
      # testedfiles: Tv.ycp

      Yast.include self, "testsuite.rb"

      @READ = { "target" => { "size" => -1, "tmpdir" => "/tmp" } }

      TESTSUITE_INIT([@READ], nil)
      Yast.import "Tv"

      TEST_It_Now(nil, nil, nil)

      # preselected should be the vendor of autodetected card
      TEST_It_Now(
        {
          "module"     => ["bttv"],
          "name"       => "My Tv_card",
          "unique_key" => "123xyz"
        },
        nil,
        nil
      )

      # preselected should be the vendor of card 64
      TEST_It_Now(
        { "name" => "my autodetected card" },
        { "card" => "64" },
        "bttv"
      )

      # preselected card has also number 64, but another module (and vendor)
      TEST_It_Now(
        { "name" => "my autodetected card" },
        { "card" => "64" },
        "other"
      )

      nil
    end

    def TEST_It_Now(auto, params, mod)
      auto = deep_copy(auto)
      params = deep_copy(params)
      DUMP("---------------")

      Tv.cards_database = []
      items = Tv.CardsDBVendorsAsItems(auto, params, mod)
      DUMP(items)

      Tv.cards_database = [
        {
          "cards" => [
            {
              "module"     => ["bttv"],
              "name"       => "Unknown bttv card",
              "parameters" => { "card" => "0" }
            },
            {
              "module"     => ["bttv"],
              "name"       => "TView99 CPH06X",
              "parameters" => { "card" => "38" }
            },
            {
              "module"     => ["other"],
              "name"       => "Some card with id 64",
              "parameters" => { "card" => "64" }
            }
          ],
          "name"  => "Other vendors"
        },
        {
          "cards" => [
            {
              "module"     => ["bttv"],
              "name"       => "ATI TV-Wonder VE",
              "parameters" => { "card" => "64" }
            }
          ],
          "name"  => "ATI"
        }
      ]
      items = Tv.CardsDBVendorsAsItems(auto, params, mod)
      DUMP(items)

      nil
    end
  end
end

Yast::TvCardsDBVendorsAsItemsClient.new.main

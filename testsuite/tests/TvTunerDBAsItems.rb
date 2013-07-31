# encoding: utf-8

module Yast
  class TvTunerDBAsItemsClient < Client
    def main
      # testedfiles: Tv.ycp

      Yast.include self, "testsuite.rb"

      @READ = { "target" => { "size" => -1, "tmpdir" => "/tmp" } }

      TESTSUITE_INIT([@READ], nil)
      Yast.import "Tv"

      Tv.tuners_database = nil
      @items = Tv.TunersDBAsItems(nil, nil)
      DUMP(@items)


      Tv.tuners_database = {}
      @items = Tv.TunersDBAsItems("bttv", nil)
      DUMP(@items)

      Tv.tuners_database = {
        "bttv" => [
          { "name" => "No tuner", "parameters" => { "tuner" => "4" } },
          { "name" => "Alps HSBH1", "parameters" => { "tuner" => "9" } }
        ]
      }
      # choosing bad tuner
      @items = Tv.TunersDBAsItems(
        "bttv",
        { "name" => "Alps HSBH2", "parameters" => { "tuner" => "15" } }
      )
      DUMP(@items)

      # choosing tuner from database
      @items = Tv.TunersDBAsItems(
        "bttv",
        { "name" => "Alps HSBH1", "parameters" => { "tuner" => "9" } }
      )
      DUMP(@items)

      nil
    end
  end
end

Yast::TvTunerDBAsItemsClient.new.main

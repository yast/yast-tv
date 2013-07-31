# encoding: utf-8

module Yast
  class TvTunersDBSelectTunerClient < Client
    def main
      # testedfiles: Tv.ycp

      Yast.include self, "testsuite.rb"

      @READ = { "target" => { "size" => -1, "tmpdir" => "/tmp" } }

      TESTSUITE_INIT([@READ], nil)
      Yast.import "Tv"

      Tv.tuners_database = nil
      @tuner = Tv.TunersDBSelectTuner("bttv", 1)
      DUMP(@tuner)


      Tv.tuners_database = {}
      @tuner = Tv.TunersDBSelectTuner("bttv", 1)
      DUMP(@tuner)

      Tv.tuners_database = {
        "bttv" => [
          { "name" => "No tuner", "parameters" => { "tuner" => "4" } },
          { "name" => "Alps HSBH1", "parameters" => { "tuner" => "9" } }
        ]
      }
      @tuner = Tv.TunersDBSelectTuner("bttv", 2)
      DUMP(@tuner)

      @tuner = Tv.TunersDBSelectTuner("bttv", 3)
      DUMP(@tuner)

      nil
    end
  end
end

Yast::TvTunersDBSelectTunerClient.new.main

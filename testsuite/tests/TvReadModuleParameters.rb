# encoding: utf-8

module Yast
  class TvReadModuleParametersClient < Client
    def main
      # testedfiles: Tv.ycp

      Yast.include self, "testsuite.rb"

      @READ = { "target" => { "size" => -1, "tmpdir" => "/tmp" } }

      TESTSUITE_INIT([@READ], nil)
      Yast.import "Tv"

      # Read() return nil
      @READ_nil = { "modules" => { "options" => nil } }

      # Read() returns empty map
      @READ_empty = { "modules" => { "options" => {} } }

      # Read() returns options for one card
      @READ_one = {
        "modules" => {
          "options" => { "bttv" => { "card" => "2", "tuner" => "5" } }
        }
      }

      # Read() returns options for three cards
      @READ_three = {
        "modules" => {
          "options" => {
            "bttv" => { "card" => ",,3", "tuner" => "a,b,c", "blah" => ",y," }
          }
        }
      }

      TEST(lambda { Tv.ReadModuleParameters(path(".modules"), "bttv") }, [
        @READ_nil,
        {},
        {}
      ], false)

      TEST(lambda { Tv.ReadModuleParameters(path(".modules"), "bttv") }, [
        @READ_empty,
        {},
        {}
      ], false)

      TEST(lambda { Tv.ReadModuleParameters(path(".modules"), "bttv") }, [
        @READ_one,
        {},
        {}
      ], false)

      #    TEST(``(Tv::ReadModuleParameters ("card")), [ READ_three , $[], $[] ], false);
      TEST(lambda { Tv.ReadModuleParameters(path(".modules"), "bttv") }, [
        @READ_three,
        {},
        {}
      ], false)

      nil
    end
  end
end

Yast::TvReadModuleParametersClient.new.main

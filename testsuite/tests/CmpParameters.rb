# encoding: utf-8

module Yast
  class CmpParametersClient < Client
    def main
      Yast.import "UI"
      # testedfiles: Tv.ycp tv/misc.ycp

      Yast.include self, "testsuite.rb"

      @READ = { "target" => { "size" => -1, "tmpdir" => "/tmp" } }

      TESTSUITE_INIT([@READ], nil)

      Yast.import "Tv" # moves "Read    .target.size "/etc/install.inf" -1" line up
      Yast.include self, "tv/misc.rb"


      TEST(lambda { CmpParameters({}, {}) }, [], nil)

      TEST(lambda { CmpParameters({ "card" => "0" }, { "card" => "0" }) }, [], nil)

      TEST(lambda do
        CmpParameters(
          { "card" => "0", "tuner" => "0" },
          { "card" => "0", "tuner" => "1" }
        )
      end, [], nil)

      TEST(lambda do
        CmpParameters({ "card" => "0", "tuner" => nil }, { "card" => "0" })
      end, [], nil)

      nil
    end
  end
end

Yast::CmpParametersClient.new.main

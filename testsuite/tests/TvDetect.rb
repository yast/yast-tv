# encoding: utf-8

module Yast
  class TvDetectClient < Client
    def main
      # testedfiles: Tv.ycp

      Yast.include self, "testsuite.rb"

      @READ = { "target" => { "size" => -1, "tmpdir" => "/tmp" } }

      TESTSUITE_INIT([@READ], nil)
      Yast.import "Tv"

      @READ_nil = { "probe" => { "tv" => nil, "dvb" => nil } }

      @READ_empty = { "probe" => { "tv" => [], "dvb" => [] } }

      @READ_det = {
        "probe" => {
          "tv"  => [
            {
              "sub_device" => "jmeno prvni",
              "unique_key" => "klic",
              "drivers"    => [{ "modules" => [] }]
            },
            {
              "device"     => "jmeno druhe",
              "unique_key" => "123xyz",
              "drivers"    => [{ "modules" => [["bttv"]] }]
            }
          ],
          "dvb" => []
        }
      }


      # Read() returns nil and invokes Report::Warning
      #     TEST (``(Tv::Detect()), [ READ_nil, $[], $[] ], nil);

      # Read() returns an empty list
      TEST(lambda { Tv.Detect }, [@READ_empty, {}, {}], nil)
      DUMP(Tv.detected_cards)

      TEST(lambda { Tv.Detect }, [@READ_det, {}, {}], nil)
      DUMP(Tv.detected_cards)

      nil
    end
  end
end

Yast::TvDetectClient.new.main

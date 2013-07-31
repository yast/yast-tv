# encoding: utf-8

module Yast
  class TvReadTunersDatabaseClient < Client
    def main
      # testedfiles: Tv.ycp

      Yast.include self, "testsuite.rb"

      @READ = { "target" => { "size" => -1, "tmpdir" => "/tmp" } }

      TESTSUITE_INIT([@READ], nil)

      textdomain "tv"
      Yast.import "Tv"

      @READ_nil = { "target" => { "yast2" => nil } }

      @READ_empty = { "target" => { "yast2" => {} } }

      @READ_db = {
        "target" => {
          "yast2" => {
            "bttv" => [
              { "name" => _("No tuner"), "parameters" => { "tuner" => "4" } },
              { "name" => "Alps HSBH1", "parameters" => { "tuner" => "9" } }
            ]
          }
        }
      }

      # cannot read the database file (creates err-file due to Report::Error)
      # Tv::tuners_database=nil;
      #     TEST (``(Tv::ReadCardsDatabase()), [ READ_nil, $[], $[] ], nil);

      # empty database
      Tv.tuners_database = nil
      TEST(lambda { Tv.ReadTunersDatabase }, [@READ_empty, {}, {}], nil)

      # doesn't read the file (card_database is not nil)
      TEST(lambda { Tv.ReadTunersDatabase }, [@READ_db, {}, {}], nil)

      Tv.tuners_database = nil
      TEST(lambda { Tv.ReadTunersDatabase }, [@READ_db, {}, {}], nil)

      nil
    end
  end
end

Yast::TvReadTunersDatabaseClient.new.main

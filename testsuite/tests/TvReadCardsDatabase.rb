# encoding: utf-8

module Yast
  class TvReadCardsDatabaseClient < Client
    def main
      # testedfiles: Tv.ycp

      Yast.include self, "testsuite.rb"

      @READ = { "target" => { "size" => -1, "tmpdir" => "/tmp" } }

      TESTSUITE_INIT([@READ], nil)

      textdomain "tv"
      Yast.import "Tv"

      @READ_nil = { "target" => { "yast2" => nil } }

      @READ_empty = [
        { "target" => { "yast2" => [] } },
        { "target" => { "yast2" => {} } },
        { "target" => { "yast2" => [] } }
      ]

      @READ_db = {
        "target" => {
          "yast2" => [
            {
              "cards" => [
                {
                  "module"     => "bttv",
                  "name"       => _("Unknown bttv card"),
                  "parameters" => { "card" => "0" }
                },
                {
                  "module"     => "bttv",
                  "name"       => "TView99 CPH06X",
                  "parameters" => { "card" => "38" }
                }
              ],
              "name"  => _("Other vendors")
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
        }
      }

      # cannot read the database file (creates err-file due to Report::Error)
      # Tv::cards_database=nil;
      #     TEST (``(Tv::ReadCardsDatabase()), [ READ_nil, $[], $[] ], nil);

      # empty database
      Tv.cards_database = nil
      TEST(lambda { Tv.ReadCardsDatabase }, [@READ_empty, {}, {}], nil)

      # doesn't read the file (card_database is not nil)
      TEST(lambda { Tv.ReadCardsDatabase }, [@READ_db, {}, {}], nil)

      Tv.cards_database = nil
      TEST(lambda { Tv.ReadCardsDatabase }, [@READ_db, {}, {}], nil)

      nil
    end
  end
end

Yast::TvReadCardsDatabaseClient.new.main

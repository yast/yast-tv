# encoding: utf-8

module Yast
  class TvProposeClient < Client
    def main
      # testedfiles: Tv.ycp Sound.ycp sound/write_routines.ycp

      Yast.include self, "testsuite.rb"

      @READ = { "target" => { "size" => -1, "tmpdir" => "/tmp" } }

      TESTSUITE_INIT([@READ], nil)
      Yast.import "Tv"

      @R = {}
      @W = {}
      @E = { "audio" => { "alsa" => { "store" => true } } }

      # Tv::cards == nil
      Tv.cards = nil
      Tv.detected_cards = [
        {
          "module"     => ["bttv"],
          "name"       => "Second detected",
          "unique_key" => "123xyz"
        }
      ]
      TEST(lambda { Tv.Propose }, [@R, @W, @E], nil)
      DUMP(Tv.cards)

      # Tv::cards == card1
      Tv.cards = [
        {
          "module"        => ["bttv"],
          "parameters"    => { "param1" => "testvalue" },
          "unique_key"    => "hluk.HvsIesmXXX1",
          "sound_card_no" => 0
        }
      ]
      Tv.detected_cards = [] # detected_cards cannot have nil value
      TEST(lambda { Tv.Propose }, [@R, @W, @E], nil)
      DUMP(Tv.cards)

      # Tv::cards == card1, nil, nil, card4
      Tv.cards = [
        {
          "module"        => ["bttv"],
          "parameters"    => { "param1" => "testvalue" },
          "unique_key"    => "hluk.HvsIesmXXX1",
          "sound_card_no" => 0
        },
        {},
        {},
        {
          "module"        => ["xyz"],
          "parameters"    => { "par_other" => "testvalue2" },
          "unique_key"    => "j7F3.J8dhgs34fK2",
          "sound_card_no" => 1
        }
      ]
      Tv.detected_cards = [
        {
          "module"     => ["zoran"],
          "name"       => "First detected",
          "unique_key" => "klic"
        },
        {
          "module"     => ["bttv"],
          "name"       => "Second detected",
          "unique_key" => "123xyz"
        }
      ]
      TEST(lambda { Tv.Propose }, [@R, @W, @E], nil)
      DUMP(Tv.cards)

      nil
    end
  end
end

Yast::TvProposeClient.new.main

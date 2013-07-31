# encoding: utf-8

module Yast
  class TvGetMajor81AliasesClient < Client
    def main
      # testedfiles: Tv.ycp

      Yast.include self, "testsuite.rb"

      @READ = { "target" => { "size" => -1, "tmpdir" => "/tmp" } }

      TESTSUITE_INIT([@READ], nil)
      Yast.import "Tv"

      # none alias
      @READ_alias_nil = { "modules" => { "alias" => nil } }

      # no char-major-81 alias
      @READ_no_alias_81 = {
        "modules" => { "alias" => { "eth0" => "", "fb0" => "", "midi" => "" } }
      }

      # one char-major-81 alias
      @READ_one_alias_81 = {
        "modules" => {
          "alias" => { "eth0" => "", "fb0" => "", "char-major-81-0" => "" }
        }
      }

      # more char-major-81 aliases
      @READ_more_aliases_81 = {
        "modules" => {
          "alias" => {
            "eth0"            => "",
            "char-major-81-0" => "",
            "char-major-81-1" => "",
            "midi"            => ""
          }
        }
      }


      TEST(lambda { Tv.GetMajor81Aliases(path(".modules")) }, [
        @READ_alias_nil,
        {},
        {}
      ], false)

      TEST(lambda { Tv.GetMajor81Aliases(path(".modules")) }, [
        @READ_no_alias_81,
        {},
        {}
      ], false)

      TEST(lambda { Tv.GetMajor81Aliases(path(".modules")) }, [
        @READ_one_alias_81,
        {},
        {}
      ], false)

      TEST(lambda { Tv.GetMajor81Aliases(path(".modules")) }, [
        @READ_more_aliases_81,
        {},
        {}
      ], false)

      nil
    end
  end
end

Yast::TvGetMajor81AliasesClient.new.main

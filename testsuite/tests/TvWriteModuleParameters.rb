# encoding: utf-8

module Yast
  class TvWriteModuleParametersClient < Client
    def main
      # testedfiles: Tv.ycp

      Yast.include self, "testsuite.rb"

      @READ = { "target" => { "size" => -1, "tmpdir" => "/tmp" } }

      TESTSUITE_INIT([@READ], nil)
      Yast.import "Tv"

      # Read() return nil
      @READ_nil = { "modules" => { "options" => {} } }

      # Dir() returns current state of bttv
      @READ_one = {
        "modules" => {
          "options" => {
            "bttv" => [
              3,
              {
                "card"  => { 0 => nil, 1 => "3", 2 => "2" },
                "tuner" => { 0 => "a", 1 => "b", 2 => "c" }
              }
            ]
          }
        }
      }

      # Write() fails
      @WRITE_false = { "modules" => { "options" => false } }

      # Write() is OK
      @WRITE_true = { "modules" => { "options" => true } }

      # parameters which should be written
      @modules_pars = {
        "bttv"    => [
          3,
          {
            "card"  => { 0 => nil, 1 => "3", 2 => "2" },
            "tuner" => { 0 => "a", 1 => "b", 2 => "c" }
          }
        ],
        "isa-pnp" => [1, { "isapnp_reset" => { 0 => "0" } }]
      }


      TEST(lambda { Tv.WriteModulesParameters(@modules_pars) }, [
        @READ_nil,
        @WRITE_false,
        {}
      ], false)

      TEST(lambda { Tv.WriteModulesParameters(@modules_pars) }, [
        @READ_nil,
        @WRITE_true,
        {}
      ], false)

      # bttv has nil parameters -> nil will be written after calling Dir()
      @modules_pars = {
        "isa-pnp" => [1, { "isapnp_reset" => { 0 => "0" } }],
        "bttv" =>
          #		[ 3, $[ nil: $[] ]]
          [3, nil]
      }

      TEST(lambda { Tv.WriteModulesParameters(@modules_pars) }, [
        @READ_one,
        @WRITE_true,
        {}
      ], false)

      nil
    end
  end
end

Yast::TvWriteModuleParametersClient.new.main

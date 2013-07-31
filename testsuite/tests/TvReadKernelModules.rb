# encoding: utf-8

module Yast
  class TvReadKernelModulesClient < Client
    def main
      # testedfiles: Tv.ycp

      Yast.include self, "testsuite.rb"

      @READ = { "target" => { "size" => -1, "tmpdir" => "/tmp" } }

      TESTSUITE_INIT([@READ], nil)
      Yast.import "Tv"

      @READ_modules = {
        "modinfo" => {
          "kernel" => {
            "drivers" => {
              "media" => {
                "video" => {
                  "bttv"  => {
                    "module_filename"    => "/lib/modules/2.4.4-4GB/kernel/drivers/media/video/bttv.o",
                    "module_description" => "bttv - v4l driver module for bt848/878 based cards",
                    "tuner"              => "specify installed tuner type"
                  },
                  "zoran" => {
                    "module_description" => "Zoran ZR36120 based framegrabber",
                    "module_filename"    => "/lib/modules/2.4.4-4GB/kernel/drivers/media/video/zoran.o"
                  }
                },
                "radio" => {
                  "miropcm20" => {
                    "module_author"      => "Ruurd Reitsma",
                    "module_description" => "A driver for the Miro PCM20 radio card.",
                    "module_filename"    => "/lib/modules/2.4.19-4GB/kernel/drivers/media/radio/miropcm20.o",
                    "radio_nr"           => ""
                  }
                }
              }
            }
          }
        }
      }

      # none kernel modules
      TEST(lambda { Tv.ReadKernelModules }, [{}, {}, {}], nil)
      DUMP(Tv.kernel_modules)
      DUMP(Tv.radio_modules)

      Tv.kernel_modules = nil #enforce new read

      TEST(lambda { Tv.ReadKernelModules }, [@READ_modules, {}, {}], nil)
      DUMP(Tv.kernel_modules)
      DUMP(Tv.radio_modules)

      nil
    end
  end
end

Yast::TvReadKernelModulesClient.new.main

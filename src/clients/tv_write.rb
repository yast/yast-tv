# encoding: utf-8

# File:	clients/tv_write.ycp
# Package:	TV cards configuration
# Summary:	Writing only client
# Authors:	Jan Holesovsky <kendy@suse.cz>
#
# $Id$
#
# This is a write-only client. It takes its arguments and just
# write the settings.

# @param first a map of tv settings
# @return [Boolean] success of operation
# @example map mm = $[ "FAIL_DELAY" : "77" ];
# @example any ret = WFM::CallModule ("tv_write", [ mm ]);
module Yast
  class TvWriteClient < Client
    def main
      Yast.import "UI"
      textdomain "tv"

      Yast.import "Tv"
      Yast.import "Progress"

      @args = WFM.Args
      if Ops.less_or_equal(Builtins.size(@args), 0)
        Builtins.y2error("NOT writing, no arguments...")
        return false
      end
      if !Ops.is_map?(WFM.Args(0))
        Builtins.y2error("Bad argument for tv write: %1", WFM.Args(0))
        return false
      end

      # The settings are in the first argument
      @settings = Ops.get_map(@args, 0, {})
      Builtins.y2milestone("Only writing... (%1)", @settings)

      return false if !Tv.Import(@settings)

      @callback = lambda { UI.PollInput == :abort }

      @progress = Progress.set(false)
      @ret = Tv.Write(@callback)
      Progress.set(@progress)

      @ret
    end
  end
end

Yast::TvWriteClient.new.main

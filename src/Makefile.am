# Sources for tv

module_DATA = \
  modules/Tv.rb \
  modules/ModulesComments.rb

client_DATA = \
  clients/tv_auto.rb \
  clients/tv.rb \
  clients/tv_proposal.rb \
  clients/tv_write.rb \
  clients/irc.rb

yncludedir = @yncludedir@/tv
ynclude_DATA = \
  include/tv/irc_ui.rb \
  include/tv/ui.rb \
  include/tv/misc.rb \
  include/tv/helps.rb

scrconf_DATA = \
  scrconf/cfg_lirc.scr \
  scrconf/xawtvrc.scr \
  scrconf/modprobe_tv.scr

ydata_DATA = \
  data/tv_dvb_cards.yml \
  data/tv_dvb_firmware.yml \
  data/tv_lirc_gpio.yml

desktop_DATA = \
  desktop/tv.desktop

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(scrconf_DATA) $(ydata_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common

#
# Makefile.am for y2c_tv/src
#
# $Id$
#

yncludedir = @yncludedir@/tv

client_DATA =			\
	tv.ycp			\
	tv_auto.ycp		\
	tv_proposal.ycp		\
	tv_write.ycp		\
	irc.ycp

ynclude_DATA =			\
	helps.ycp		\
	misc.ycp		\
	ui.ycp			\
	irc_ui.ycp

config_DATA =			\
	tv.y2cc

desktop_DATA =			\
	tv.desktop

module_DATA =			\
	Tv.ycp			\
	ModulesComments.ycp

YCPCFLAGS = -I .

ycpchook = tv

tv:
	ln -s . tv

EXTRA_DIST = $(client_DATA) $(desktop_DATA) $(ynclude_DATA) $(config_DATA) $(module_DATA)

include $(top_srcdir)/Makefile.am.common

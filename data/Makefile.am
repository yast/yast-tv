#
# Makefile.am for tv/data
#
# $Id$
#

# TODO FIXME: The following must go away!!!
ydatadir = $(yast2dir)

ydata_DATA = tv_cards.ycp tv_tuners.ycp

tv_cards.ycp: CARDLIST.bttv CARDLIST.saa7134
	$(srcdir)/create_tv_db $^ > $@

tv_tuners.ycp: CARDLIST.bttv
	$(srcdir)/create_tuner_db $^ > $@

CLEANFILES = $(ydata_DATA)

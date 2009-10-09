#
# Makefile.am for tv/data
#
# $Id$
#

ydata_DATA = tv_cards-lirc_gpio.ycp tv_cards.ycp tv_tuners.ycp tv_dvbcards.ycp tv_dvbfirmware.ycp

tv_cards.ycp: CARDLIST.bttv CARDLIST.saa7134 CARDLIST.cx88 CARDLIST.ivtv CARDLIST.em28xx CARDLIST.cx23885
	$(srcdir)/create_tv_db $^ > $@

tv_tuners.ycp: CARDLIST.tuner
	$(srcdir)/create_tuner_db $^ > $@

EXTRA_DIST = CARDLIST.bttv CARDLIST.saa7134 CARDLIST.cx88 CARDLIST.ivtv CARDLIST.tuner CARDLIST.em28xx CARDLIST.cx23885 \
	     create_tv_db create_tuner_db tv_cards-lirc_gpio.ycp tv_dvbcards.ycp tv_dvbfirmware.ycp

# delete generated files
CLEANFILES = tv_cards.ycp tv_tuners.ycp

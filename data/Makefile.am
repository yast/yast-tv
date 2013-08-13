#
# Makefile.am for tv/data
#
# $Id$
#

ydata_DATA = tv_cards.yml tv_tuners.yml

db_input_files = CARDLIST.bttv CARDLIST.saa7134 CARDLIST.cx88 CARDLIST.ivtv CARDLIST.em28xx CARDLIST.cx23885 CARDLIST.saa7164 CARDLIST.au0828 CARDLIST.tm6000 CARDLIST.usbvision

tv_cards.yml: $(db_input_files) create_tv_db.rb
	$(srcdir)/create_tv_db.rb $(db_input_files) > $@

tv_tuners.yml: CARDLIST.tuner create_tuner_db.rb
	$(srcdir)/create_tuner_db.rb CARDLIST.tuner > $@

EXTRA_DIST = $(db_input_files) CARDLIST.tuner create_tv_db.rb create_tuner_db.rb

# delete generated files
CLEANFILES = tv_cards.yml tv_tuners.yml


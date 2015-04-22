all check install installdirs installcheck uninstall dep depend clean distclean maintainer-clean dist:
	@if [ ! -f GNUmakefile ] ; then \
		echo "You need to run the 'configure' program first. See the file"; \
		echo "'README' for installation instructions." ; \
		false ; \
	fi
	@IFS=':' ; \
		for dir in $$PATH; do \
			for prog in gmake gnumake make; do \
				if [ -f $$dir/$$prog ] && ( $$dir/$$prog -f /dev/null --version 2>/dev/null | grep GNU >/dev/null 2>&1 ) ; then \
					GMAKE=$$dir/$$prog; \
					break 2; \
				fi; \
			done; \
		done; \
	\
	if [ x"$${GMAKE+set}" = xset ]; then \
		echo "Using GNU make found at $${GMAKE}"; \
		$${GMAKE} $@ ; \
	else \
		echo "You must use GNU make to build slony-I." ; \
		false; \
	fi

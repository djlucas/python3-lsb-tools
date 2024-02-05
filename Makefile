ifeq ($(V),)
Q = @
endif

PYTHON ?= python3
PY_COMPILE = $(Q)$(PYTHON) -m py_compile

pysrc_to_pyc = \
  $(shell $(PYTHON) -c "from importlib.util import cache_from_source; \
                        print(cache_from_source('lsbtools/$(1)'))")

LSBTOOLS_PYC = $(call pysrc_to_pyc,lsbtools.py)
INSTALL_INITD_PYC = $(call pysrc_to_pyc,install_initd.py)
LSB_RELEASE_PYC = $(call pysrc_to_pyc,lsb_release.py)
REMOVE_INITD_PYC = $(call pysrc_to_pyc,remove_initd.py)

ALL_PYC = $(LSBTOOLS_PYC) $(INSTALL_INITD_PYC) $(LSBINSTALL_PYC) \
          $(LSB_RELEASE_PYC) $(REMOVE_INITD_PYC)

ENTRY_POINT = install_initd.ent lsb_release.ent remove_initd.ent

PYLIB_DIR = $(shell $(PYTHON) -c "import sysconfig; \
                                  print(sysconfig.get_path('purelib'))")

.PHONY: all clean install
all: $(ALL_PYC) $(ENTRY_POINT)

clean: ; $(RM) $(ALL_PYC) $(ENTRY_POINT) python.shebang s-python-shebang

install: all
	mkdir -pv $(DESTDIR)/$(PYLIB_DIR)
	cp -av --no-preserve=ownership lsbtools \
	   -T  $(DESTDIR)/$(PYLIB_DIR)/lsbtools
	install -D -vm755 lsb_release.ent $(DESTDIR)/usr/bin/lsb_release
	install -vdm 755 $(DESTDIR)/usr/sbin
	for i in install_initd remove_initd; do     \
	  install -D -vm755 $$i.ent $(DESTDIR)/usr/lib/lsb/$$i;\
	  rm -fv $(DESTDIR)/usr/sbin/$$i;                      \
	  ln -sv ../lib/lsb/$$i $(DESTDIR)/usr/sbin;           \
	done
	mkdir -pv $(DESTDIR)/usr/share/man/man1
	install -vm644 man/lsb_release.1 $(DESTDIR)/usr/share/man/man1
	mkdir -pv $(DESTDIR)/usr/share/man/man8
	install -vm644 man/*.8 $(DESTDIR)/usr/share/man/man8

$(LSBTOOLS_PYC): lsbtools/lsbtools.py
	@echo '[PY_COMPILE] ' $@
	$(PY_COMPILE) $<

$(INSTALL_INITD_PYC): lsbtools/install_initd.py
	@echo '[PY_COMPILE] ' $@
	$(PY_COMPILE) $<

$(LSB_RELEASE_PYC): lsbtools/lsb_release.py
	@echo '[PY_COMPILE] ' $@
	$(PY_COMPILE) $<

$(REMOVE_INITD_PYC): lsbtools/remove_initd.py
	@echo '[PY_COMPILE] ' $@
	$(PY_COMPILE) $<

%.ent: python.shebang
	@echo '[GEN]        ' $@
	$(Q)cp $< $@
	$(Q)echo "from lsbtools import $(patsubst %.ent,%,$@)" >> $@

python.shebang: s-python-shebang; @echo '[UPD]        ' $@

.PHONY: s-python-shebang
s-python-shebang:
	$(Q)$(PYTHON) -c                                               \
	  "import sys,os;print('#!'+os.path.realpath(sys.executable))" \
	  > tmp-python.shebang
	$(Q)if ! diff &> /dev/null tmp-python.shebang python.shebang; then \
	  mv tmp-python.shebang python.shebang;                            \
	fi
	$(Q)$(RM) tmp-python.shebang
	$(Q)touch s-python-shebang

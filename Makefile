DESTDIR=/usr/local/

all:
	@echo "Options:"
	@echo "  install DESTDIR=destdir"
	@echo "  deb"

install:
	mkdir -p ${DESTDIR}/usr/bin/
	mkdir -p ${DESTDIR}/etc/systemd/system/
	mkdir -p ${DESTDIR}/etc/default/
	cp midiconfigfs.sh ${DESTDIR}/usr/bin/
	cp midiconfigfs.service ${DESTDIR}/etc/systemd/system/
	cp midiconfigfs.default ${DESTDIR}/etc/default/midiconfigfs

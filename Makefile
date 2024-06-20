.POSIX:
.SUFFIXES:

HARE=hare
HAREFLAGS=

DESTDIR=
PREFIX=/usr/local/
BINDIR=$(PREFIX)bin/
PROJECT_NAME=lispyha

all: $(PROJECT_NAME)

$(PROJECT_NAME):
	$(HARE) build $(HAREFLAGS) -o $@ cmd/$@/

check:
	$(HARE) test $(HAREFLAGS)

clean:
	rm -f $(PROJECT_NAME)

install:
	install -Dm755 $(PROJECT_NAME) $(DESTDIR)$(BINDIR)$(PROJECT_NAME)

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/$(PROJECT_NAME)

.PHONY: all check clean install uninstall

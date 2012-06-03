# build mode: 32bit or 64bit
ifeq (,$(MODEL))
	MODEL := 64
endif

ifeq (,$(DMD))
	DMD := dmd
endif

LIB     = libarangod.a
DFLAGS  = -Isrc -m$(MODEL) -w -d -property

ifeq ($(BUILD),debug)
	DFLAGS += -g -debug
else
	DFLAGS += -O -release -nofloat -inline
endif

NAMES = database cursor collection document query index util
FILES = $(addsuffix .d, $(NAMES))
SRCS  = $(addprefix src/arango/, $(FILES))

# DDoc
DOCS      = $(addsuffix .html, $(NAMES))
DOCDIR    = doc
CANDYDOC  = $(addprefix doc/candydoc/, candy.ddoc modules.ddoc)
DDOCFLAGS = -Dd$(DOCDIR) -c -o- -Isrc $(CANDYDOC)

target: $(LIB) ddoc

$(LIB):
	$(DMD) $(DFLAGS) -lib -of$(LIB) $(SRCS)

ddoc:
	$(DMD) $(DDOCFLAGS) $(SRCS)

clean:
	rm $(addprefix $(DOCDIR)/, $(DOCS)) $(LIB)

MAIN_FILE = "empty_arango_unittest.d"

UNITTEST_DFLAGS = $(DFLAGS) -unittest -L-lcurl

unittest:
	echo 'import arango.database; void main(){}' > $(MAIN_FILE)
	$(DMD) $(UNITTEST_DFLAGS) $(SRCS) -run $(MAIN_FILE)
	rm $(MAIN_FILE)

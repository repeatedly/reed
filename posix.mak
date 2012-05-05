# build mode: 32bit or 64bit
ifeq (,$(MODEL))
	MODEL := 32 # Why libavocadod.a with -m64 doesn't work on Mac?
endif

ifeq (,$(DMD))
	DMD := dmd
endif

LIB     = libavocadod.a
DFLAGS  = -Isrc -m$(MODEL) -w -d -property

ifeq ($(BUILD),debug)
	DFLAGS += -g -debug
else
	DFLAGS += -O -release -nofloat -inline
endif

NAMES = database collection document query util
FILES = $(addsuffix .d, $(NAMES))
SRCS  = $(addprefix src/avocado/, $(FILES))

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

MAIN_FILE = "empty_avocado_unittest.d"

# Why linking with -m64 fails on Mac?
UNITTEST_DFLAGS = $(DFLAGS) -unittest -L-lcurl

unittest:
	echo 'import avocado.database; void main(){}' > $(MAIN_FILE)
	$(DMD) $(UNITTEST_DFLAGS) $(SRCS) -run $(MAIN_FILE)
	rm $(MAIN_FILE)

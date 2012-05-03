# build mode: 32bit or 64bit
ifeq (,$(MODEL))
	MODEL := 64
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

NAMES = database util
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

unittest:
	echo 'import avocado.database; void main(){}' > $(MAIN_FILE)
	$(DMD) $(DFLAGS) -unittest -of$(LIB) $(SRCS) -run $(MAIN_FILE)
	rm $(MAIN_FILE)

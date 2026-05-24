# Makefile for robert
#
# Prerequisites:
#   ../mruby    # mruby checkout (sibling directory)
#
# Quick start:
#   make        # build toolchain and run tests
#   make test   # run tests
#   make clean  # clean build artifacts

MRUBY_DIR    ?= ../mruby
BUILD_CONFIG  = build.rb
BUILD_NAME    = robert
BUILD_DIR     = $(MRUBY_DIR)/build/$(BUILD_NAME)
BUILD ?= test
RUBY_GEM_FILES != find mrblib -type f 2>/dev/null | sort

ENTRYPOINT = src/main.rb
STANDALONE_FILES = main.c
STANDALONE_BIN = bin/robert
STANDALONE_IREP = tmp/robert_main.c
STANDALONE_OBJ = tmp/main.o

PROMPT_SRC    = data/prompt.md
PROMPT_IN     = data/prompt.rb.in
PROMPT_OUT    = build/mrblib/robert/prompt.rb

TOOLCHAIN_BIN  = bin/mruby bin/mrbc bin/mruby-config
TOOLCHAIN_STAMP = tmp/toolchain.$(BUILD).stamp

.if ${BUILD} == "production"
MRBC_FLAGS = --remove-lv
POST_BUILD = strip $(STANDALONE_BIN)
.else
MRBC_FLAGS =
POST_BUILD = true
.endif

.PHONY: all toolchain standalone clean distclean

all: toolchain standalone

toolchain: $(TOOLCHAIN_STAMP)

standalone: $(STANDALONE_BIN)

$(TOOLCHAIN_STAMP): $(BUILD_CONFIG) mrbgem.rake $(RUBY_GEM_FILES) $(PROMPT_OUT)
	mkdir -p tmp bin
	ruby -C $(MRUBY_DIR) minirake clean 2>/dev/null || true
	BUILD=$(BUILD) ruby -C $(MRUBY_DIR) minirake MRUBY_CONFIG=$$(pwd)/$(BUILD_CONFIG)
	cp -r $(BUILD_DIR)/bin/* bin/
	touch $(TOOLCHAIN_STAMP)

$(STANDALONE_IREP): $(ENTRYPOINT) $(TOOLCHAIN_STAMP)
	mkdir -p tmp
	bin/mrbc $(MRBC_FLAGS) -B robert_main -o $(STANDALONE_IREP) $(ENTRYPOINT)

$(STANDALONE_OBJ): main.c $(TOOLCHAIN_STAMP)
	mkdir -p tmp
	$$(bin/mruby-config --cc) \
		$$(bin/mruby-config --cflags) \
		-I $(BUILD_DIR)/include \
		-c main.c \
		-o $(STANDALONE_OBJ)

$(STANDALONE_BIN): $(STANDALONE_OBJ) $(STANDALONE_IREP) $(TOOLCHAIN_STAMP) $(STANDALONE_FILES)
	mkdir -p bin
	$$(bin/mruby-config --ld) -o $(STANDALONE_BIN) \
		$(STANDALONE_OBJ) \
		$(STANDALONE_IREP) \
		$$(bin/mruby-config --ldflags-before-libs) \
		$(BUILD_DIR)/lib/libmruby.a \
		$$(bin/mruby-config --ldflags) \
		$$(bin/mruby-config --libs | sed 's/-lmruby//g')
	$(POST_BUILD)
	chmod 755 $(STANDALONE_BIN)

$(PROMPT_OUT): $(PROMPT_IN) $(PROMPT_SRC)
	mkdir -p build/mrblib/robert
	ruby -e "puts File.read('$(PROMPT_IN)').sub('__PROMPT__', File.read('$(PROMPT_SRC)'))" > $(PROMPT_OUT)

clean:
	rm -f $(TOOLCHAIN_BIN)
	rm -f tmp/toolchain.*.stamp
	rm -f $(STANDALONE_BIN) $(STANDALONE_IREP) $(STANDALONE_OBJ)
	rm -f $(PROMPT_OUT)

distclean: clean
	rm $$(pwd)/*.lock || true
	rm -rf $(BUILD_DIR)
	rm -rf $(MRUBY_DIR)/build/repos/$(BUILD_NAME)

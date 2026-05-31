# Makefile for robert
#
# Prerequisites:
#   ../mruby    # mruby checkout (sibling directory)
#
# Quick start:
#   make        # build toolchain and run tests
#   make test   # run tests
#   make clean  # clean build artifacts
#   make install  # install binary and man page to $(PREFIX)

MRUBY_DIR    ?= ../mruby
BUILD_CONFIG  = build.rb
BUILD_NAME    = robert
BUILD_DIR     = $(MRUBY_DIR)/build/$(BUILD_NAME)
BUILD ?= test
RUBY_GEM_FILES != find mrblib -type f 2>/dev/null | sort
SPEC_FILES != find spec -type f -name '*_spec.rb' 2>/dev/null | sort

PREFIX      ?= /usr/local
MANPREFIX   ?= $(PREFIX)/man

CURL_VERSION    ?= 8.20.0
MBEDTLS_VERSION ?= 3.6.5
NGHTTP2_VERSION ?= 1.69.0
STATIC_PREFIX   ?= ${.CURDIR}/vendor/static
STATIC_DISTDIR  ?= ${.CURDIR}/vendor/dist
STATIC_BUILDDIR ?= ${.CURDIR}/vendor/build
STATIC_JOBS     ?= 2
CA_BUNDLE       ?= /etc/ssl/cert.pem
FETCH           ?= fetch
GMAKE           ?= gmake

CURL_TARBALL    = $(STATIC_DISTDIR)/curl-$(CURL_VERSION).tar.xz
CURL_SRCDIR     = $(STATIC_BUILDDIR)/curl-$(CURL_VERSION)
CURL_URL        = https://curl.se/download/curl-$(CURL_VERSION).tar.xz
MBEDTLS_TARBALL = $(STATIC_DISTDIR)/mbedtls-$(MBEDTLS_VERSION).tar.bz2
MBEDTLS_SRCDIR  = $(STATIC_BUILDDIR)/mbedtls-$(MBEDTLS_VERSION)
MBEDTLS_URL     = https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-$(MBEDTLS_VERSION)/mbedtls-$(MBEDTLS_VERSION).tar.bz2
NGHTTP2_TARBALL = $(STATIC_DISTDIR)/nghttp2-$(NGHTTP2_VERSION).tar.xz
NGHTTP2_SRCDIR  = $(STATIC_BUILDDIR)/nghttp2-$(NGHTTP2_VERSION)
NGHTTP2_URL     = https://github.com/nghttp2/nghttp2/releases/download/v$(NGHTTP2_VERSION)/nghttp2-$(NGHTTP2_VERSION).tar.xz

STATIC_CFLAGS   = -O2 -ffunction-sections -fdata-sections -DNDEBUG
STATIC_LDFLAGS  = -Wl,--gc-sections

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

.PHONY: all toolchain standalone static static-deps static-clean test clean distclean install

all: toolchain standalone

static: static-deps
	$(MAKE) BUILD=production STATIC=1 CURLDIR=$(STATIC_PREFIX) standalone

static-deps: $(STATIC_PREFIX)/lib/libcurl.a $(STATIC_PREFIX)/lib/libmbedtls.a $(STATIC_PREFIX)/lib/libnghttp2.a

toolchain: $(TOOLCHAIN_STAMP)

standalone: $(STANDALONE_BIN)

test: toolchain
.for spec in $(SPEC_FILES)
	bin/mruby $(spec)
.endfor

$(CURL_TARBALL):
	mkdir -p $(STATIC_DISTDIR)
	$(FETCH) -o $(CURL_TARBALL) $(CURL_URL)

$(MBEDTLS_TARBALL):
	mkdir -p $(STATIC_DISTDIR)
	$(FETCH) -o $(MBEDTLS_TARBALL) $(MBEDTLS_URL)

$(NGHTTP2_TARBALL):
	mkdir -p $(STATIC_DISTDIR)
	$(FETCH) -o $(NGHTTP2_TARBALL) $(NGHTTP2_URL)

$(STATIC_PREFIX)/lib/libmbedtls.a: $(MBEDTLS_TARBALL)
	rm -rf $(MBEDTLS_SRCDIR)
	mkdir -p $(STATIC_BUILDDIR) $(STATIC_PREFIX)
	tar -xf $(MBEDTLS_TARBALL) -C $(STATIC_BUILDDIR)
	$(GMAKE) -C $(MBEDTLS_SRCDIR) lib CFLAGS="$(STATIC_CFLAGS)" -j$(STATIC_JOBS)
	mkdir -p $(STATIC_PREFIX)/include $(STATIC_PREFIX)/lib
	cp -R $(MBEDTLS_SRCDIR)/include/mbedtls $(STATIC_PREFIX)/include/
	cp -R $(MBEDTLS_SRCDIR)/include/psa $(STATIC_PREFIX)/include/
	cp $(MBEDTLS_SRCDIR)/library/libmbedtls.a $(STATIC_PREFIX)/lib/
	cp $(MBEDTLS_SRCDIR)/library/libmbedx509.a $(STATIC_PREFIX)/lib/
	cp $(MBEDTLS_SRCDIR)/library/libmbedcrypto.a $(STATIC_PREFIX)/lib/

$(STATIC_PREFIX)/lib/libnghttp2.a: $(NGHTTP2_TARBALL)
	rm -rf $(NGHTTP2_SRCDIR)
	mkdir -p $(STATIC_BUILDDIR) $(STATIC_PREFIX)
	tar -xf $(NGHTTP2_TARBALL) -C $(STATIC_BUILDDIR)
	cd $(NGHTTP2_SRCDIR) && env \
		CFLAGS="$(STATIC_CFLAGS)" \
		CXXFLAGS="$(STATIC_CFLAGS)" \
		LDFLAGS="$(STATIC_LDFLAGS)" \
		./configure \
			--prefix=$(STATIC_PREFIX) \
			--disable-shared \
			--enable-static \
			--enable-lib-only \
			--disable-app \
			--disable-examples \
			--disable-python-bindings \
			--disable-threads
	$(GMAKE) -C $(NGHTTP2_SRCDIR) -j$(STATIC_JOBS)
	$(GMAKE) -C $(NGHTTP2_SRCDIR) install

$(STATIC_PREFIX)/lib/libcurl.a: $(CURL_TARBALL) $(STATIC_PREFIX)/lib/libmbedtls.a $(STATIC_PREFIX)/lib/libnghttp2.a
	rm -rf $(CURL_SRCDIR)
	mkdir -p $(STATIC_BUILDDIR) $(STATIC_PREFIX)
	tar -xf $(CURL_TARBALL) -C $(STATIC_BUILDDIR)
	cd $(CURL_SRCDIR) && env \
		CPPFLAGS="-I$(STATIC_PREFIX)/include" \
		CFLAGS="$(STATIC_CFLAGS)" \
		LDFLAGS="-L$(STATIC_PREFIX)/lib $(STATIC_LDFLAGS)" \
		./configure \
			--prefix=$(STATIC_PREFIX) \
			--disable-shared \
			--enable-static \
			--disable-all \
			--enable-http \
			--enable-symbol-hiding \
			--disable-manual \
			--enable-threaded-resolver \
			--with-ca-bundle=$(CA_BUNDLE) \
			--without-ca-path \
			--without-brotli \
			--without-gssapi \
			--without-libidn2 \
			--without-libpsl \
			--with-nghttp2=$(STATIC_PREFIX) \
			--without-nghttp3 \
			--without-ngtcp2 \
			--without-openssl \
			--without-quiche \
			--without-zlib \
			--without-zstd \
			--with-mbedtls=$(STATIC_PREFIX)
	$(GMAKE) -C $(CURL_SRCDIR) -j$(STATIC_JOBS)
	$(GMAKE) -C $(CURL_SRCDIR) install

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

static-clean:
	rm -rf $(STATIC_BUILDDIR) $(STATIC_PREFIX)

clean:
	rm -f $(TOOLCHAIN_BIN)
	rm -f tmp/toolchain.*.stamp
	rm -f $(STANDALONE_BIN) $(STANDALONE_IREP) $(STANDALONE_OBJ)
	rm -f $(PROMPT_OUT)

distclean: clean
	rm $$(pwd)/*.lock || true
	rm -rf $(BUILD_DIR)
	rm -rf $(MRUBY_DIR)/build/repos/$(BUILD_NAME)

install: $(STANDALONE_BIN)
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	mkdir -p $(DESTDIR)$(MANPREFIX)/man1
	install -m 755 $(STANDALONE_BIN) $(DESTDIR)$(PREFIX)/bin/robert
	install -m 644 man/man1/robert.1 $(DESTDIR)$(MANPREFIX)/man1/robert.1

#!/usr/bin/make -f
#
# Run with desired targets, typically either no args (which is the
# same as "all" below), or a key/cert pair.
#  Eg: ./tls.make myclient.key myclient.crt
#
# Adapted from: https://github.com/anguslees/helm-security-post/blob/master/tls.make

KEYSIZE = 4096
DAYS = 10000
OPENSSL = openssl
OUT = certs

all: $(OUT)/ca.crt $(OUT)/tiller.key $(OUT)/tiller.crt $(OUT)/myclient.crt $(OUT)/myclient.key

%.key:
	@mkdir -p $(@D)
	$(OPENSSL) genrsa -out $@ $(KEYSIZE)

$(OUT)/ca.crt: $(OUT)/ca.key
	$(OPENSSL) req \
	 -x509 -new -nodes -sha256 \
	 -key $< \
	 -days $(DAYS) \
	 -out $@ \
	 -extensions v3_ca \
	 -subj '/CN=tiller-CA'

$(OUT)/%.csr: $(OUT)/%.key
	$(OPENSSL) req \
	 -new -sha256 \
	 -key $< \
	 -out $@ \
	 -subj '/CN=$*'

$(OUT)/%.crt: $(OUT)/%.csr $(OUT)/ca.key $(OUT)/ca.crt
	$(OPENSSL) x509 \
	 -req \
	 -in $< \
	 -out $@ \
	 -CA $(OUT)/ca.crt \
	 -CAkey $(OUT)/ca.key \
	 -CAcreateserial \
	 -days $(DAYS) \
	 -extensions v3_ext

.NOTPARALLEL:
.PRECIOUS: $(OUT)/ca.key $(OUT)/ca.srl
FROM busybox

ADD https://github.com/pts/staticpython/raw/1bb2cf2ad24a98cc2ec6bb977bc6406bec8a8683/release/python3.2-static /bin/python
RUN chmod +x /bin/python

ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

WORKDIR /var/www/
ADD . .
EXPOSE 8080
CMD [ "/bin/python", "-m", "http.server", "8080" ]

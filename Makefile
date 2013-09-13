doc:
	mkdir -p doc/html
	asciidoc -b html -o doc/html/README.html README

clean:
	rm doc/html/README.html
	rmdir doc/html
	rmdir doc

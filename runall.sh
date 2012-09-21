#!/bin/bash
perl -Ilib scripts/make_pages.pl \
	--imagedir=images \
	--template=templates/index.tmpl \
	--outfile=html/index.html \
	--metadata=metadata/BrahmsExtract20120530.txt \
	--extension=png \
	--css styles/display.css \
	--css styles/table.css \
	--js scripts/prototype.js \
	--js scripts/enhance.js \
	--js scripts/sortable.js \
	--icons preview=styles/camera.png \
	--icons world=styles/world.png \
	--icons tomato=styles/tomato_small.png \
	--splash=images/png/G7001.png \
        -v -v -v
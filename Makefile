SHELL := /bin/bash
DATE := $(shell date "+%Y%m%d%H%M%S")
HOST := "10.70.172.31"
#HOST := "localhost"

.PHONY: ansible tilemaker icons

install-ubuntu:
	sudo apt-get install osmium-tool podman
	npm install -g @indoorequal/spritezero-cli

tiles/baden-wuerttemberg.osm.pbf:
	curl --create-dirs --fail https://download.geofabrik.de/europe/germany/baden-wuerttemberg-latest.osm.pbf -o $@

tiles/stuttgart.osm.pbf: tiles/baden-wuerttemberg.osm.pbf
	osmium extract tiles/baden-wuerttemberg.osm.pbf --polygon tilemaker/stuttgart.geojson -o $@ --overwrite

prepare-input: icons tiles/stuttgart.osm.pbf
	cp tilemaker/* tiles
	jq ". | .settings.filemetadata.tiles=[\"http://$(HOST):8080/{z}/{x}/{y}.pbf\"]" tilemaker/config-openmaptiles.json > tiles/temp.json
	mv tiles/temp.json tiles/config-openmaptiles.json

	mkdir -p tiles/tiles

	cp -r sprite* tiles/tiles/

icons:
	spritezero sprite icons
	spritezero --retina sprite@2x icons

tilemaker: prepare-input
	#jinja2 style.jinja.json -o style.json
	jq ". | .sources.openmaptiles.url=\"http://$(HOST):8080/metadata.json\" | .sprite=\"http://$(HOST):8080/sprite\"" style.json > tiles/tiles/style.json

	podman run \
		-it \
		-v $(PWD)/tiles/:/srv:z \
		--name tilemaker-map \
		--rm \
		ghcr.io/leonardehrenfried/tilemaker:latest \
		/srv/stuttgart.osm.pbf \
		--output=/srv/tiles/  \
		--config=/srv/config-openmaptiles.json \
		--process=/srv/process-openmaptiles.lua

	cp index.html tiles/tiles

	python3 -m http.server 8080 --directory tiles/tiles/


tileserver: prepare-input
	cp tilemaker/tileserver-config.json tiles/tiles
	podman run \
		-it \
		-v $(PWD)/tiles/:/srv:z \
		--name tilemaker-map \
		--rm \
		ghcr.io/leonardehrenfried/tilemaker:latest \
		/srv/stuttgart.osm.pbf \
		--output=/srv/tiles/stuttgart.mbtiles  \
		--config=/srv/config-openmaptiles.json \
		--process=/srv/process-openmaptiles.lua

	jq ". | .sources.openmaptiles.url=\"mbtiles://{v3}\" | .sprite=\"{style}\"" style.json > tiles/tiles/style.json

	mkdir -p tiles/tiles/sprites/
	cp sprite.json tiles/tiles/sprites/style.json
	cp sprite.png tiles/tiles/sprites/style.png

	cp sprite@2x.json tiles/tiles/sprites/style@2x.json
	cp sprite@2x.png tiles/tiles/sprites/style@2x.png

	podman run --rm \
    	--name tileserver \
        -v `pwd`/tiles/tiles/:/data:z \
        -p 8080:8080 docker.io/maptiler/tileserver-gl:v5.1.1 \
        --config tileserver-config.json

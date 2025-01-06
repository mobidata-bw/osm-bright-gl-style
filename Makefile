SHELL := /bin/bash
DATE := $(shell date "+%Y%m%d%H%M%S")

.PHONY: ansible tilemaker icons

install-ubuntu:
	npm install -g @indoorequal/spritezero-cli
	sudo apt-get install osmium-tool

tiles/baden-wuerttemberg.osm.pbf:
	curl --create-dirs --fail https://download.geofabrik.de/europe/germany/baden-wuerttemberg-latest.osm.pbf -o $@

tiles/stuttgart.osm.pbf: tiles/baden-wuerttemberg.osm.pbf
	osmium extract tiles/baden-wuerttemberg.osm.pbf --polygon tilemaker/stuttgart.geojson -o $@ --overwrite

tilemaker: tiles/stuttgart.osm.pbf icons
	cp tilemaker/* tiles
	jq '. | .settings.filemetadata.tiles=["http://localhost:8123/{z}/{x}/{y}.pbf"]' tilemaker/config-openmaptiles.json > tiles/temp.json
	mv tiles/temp.json tiles/config-openmaptiles.json

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

	cp -r sprite* tiles/tiles/

	cp index.html tiles/tiles

	#jinja2 style.jinja.json -o style.json
	jq '. | .sources.openmaptiles.url="http://localhost:8123/metadata.json" | .sprite="http://localhost:8123/sprite"' style.json > tiles/tiles/style.json

	python3 -m http.server 8123 --directory tiles/tiles/


icons:
	spritezero sprite icons
	spritezero --retina sprite@2x icons

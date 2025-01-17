# NWBW Bright

A GL JS basemap style showcasing OpenStreetMap. It is using the vector tile schema of [OpenMapTiles](https://github.com/openmaptiles/openmaptiles).

## Preview

To develop the style itself, use the following make command:

```
make tilemaker
```

This does the following:

- This downloads the OSM data for Baden-Württemberg and cuts out the city center of Stuttgart. 
- Uses tilemaker to build vector tiles for Stuttgart.
- Starts a web server with a preview of the style.

## Deploying to ansible

If you're satisfied with the style, then use the following make command to copy the style and sprite
data to the repository [`otp-dt-ansible`](https://github.com/mobidata-bw/otp-dt-ansible).

```
make copy-to-ansible
```

Afterwards use the regular ansible deployment process.
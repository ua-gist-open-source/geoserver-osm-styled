
# Nicely styling OSM Data in Geoserver
## Background
In previous assignments we downloaded shapefiles extracts from OSM and found them very difficult to style. In this assignment, we will use yet another method for importing OSM data: `imposm` and someone else's symbology pre-configured for a geoserver usage. This assignment borrows centrally from a single tutorial source but deviates in order to accomodate our docker-based geoserver and postgis installations. We will build on a previous assignment by re-using and re-importing the Hawaii OSM data extract.

## Deliverables
- `screencap-final.png`

We are following this tutorial:
https://github.com/geosolutions-it/osm-styles/blob/master/README.md

### 1. Clone the osm-styles repo
Clone [this repo](https://github.com/geosolutions-it/osm-styles.git) in your codespace.

This is a pre-configured copy of a geoserver data directory with styles, layers, stores, and layergroups in a nice OSM style. We will copy it into a new directory that will replace the  geoserver data directory from previously but give it a new name. 

```
git clone https://github.com/geosolutions-it/osm-styles.git
```

### 2. Setup the low-res OSM Geopackage

Download the low-resolution OSM Geopackage to the `data_dir/data` directory. This is about 1.9GB so it will take awhile.

```
curl -L https://www.dropbox.com/s/bqzxzkpmpybeytr/osm-lowres.gpkg?dl=1 -o osm-styles/data/osm-lowres.gpkg
```

### 3. Start up geoserver
 This assignment repo contains a new [`docker-compose.yml`](./docker-compose.yml) that you can use but you will need to update the volume mappings as you did before. In addition, we have turned _off_ sample data and enabled two extensions: [`css-plugin`](https://docs.geoserver.org/latest/en/user/styling/css/install.html) and [`Pregeneralized features`](https://docs.geoserver.org/stable/en/user/data/vector/featurepregen.html). We enable these plugins as per the documentation on the [kartoza/geoserver](https://github.com/kartoza/docker-geoserver#default-installed--plugins) docker hub by adding this environment variable:

```
      - STABLE_EXTENSIONS=css-plugin,feature-pregeneralized-plugin
```

Launch your `postgis` and `geoserver` containers from the shell with 
```
docker compose up -d
``` 
### 4. Create a `hawaii` database

Next you will need to create a `hawaii` database in postgresql.
```
psql -U postgres -c "CREATE DATABASE hawaii"
psql -U postgres -d hawaii -c "CREATE EXTENSION postgis"
psql -U postgres -d hawaii -c "CREATE EXTENSION hstore"
```
If you get the error `connection to server failed` it may be that postgresql container is still booting up. Try again.

### 5. Download OSM Data for Hawaii
You will download Hawaii OSM data in the pbf format. It is available from [download `hawaii-latest.osm.pbf` from Geofabrik](https://download.geofabrik.de/north-america/us/hawaii-latest.osm.pbf)


```
curl -L -O https://download.geofabrik.de/north-america/us/hawaii-latest.osm.pbf -o hawaii-latest.osm.pbf
```

### 6. Import OSM data

I created a `[Dockerfile](./Dockerfile)` that contains the [imposm3](https://imposm.org/docs/imposm3/latest/tutorial.html) executable. This is the OSM Importer that will import OSM data into the schema that will work with our new styles.


This section serves as an alternate method for [The OSM PostGIS Database](https://github.com/geosolutions-it/osm-styles#the-osm-postgis-database) from the osm-styles README. Essentially, we are going to run `imposm` with:
- volume mapping containing the `imposm/mapping.yml` file from the osm-styles repo
- same volume mapping containing the `hawaii-latest.osm.pbf` file
- on the `gist604b` network so it can communicate with our postgis instance


```
/opt/imposm/imposm-0.11.1-linux-x86-64/imposm import -mapping osm-styles/imposm/mapping.yml -read hawaii-latest.osm.pbf -overwritecache -write -connection postgis://postgres:postgres@localhost/hawaii
```

### 7. Fix the `osm` data store in geoserver
Open geoserver in your browser. Since this is a pre-configured geoserver with placeholders for the OSM store we will need to update it to make it work. 

Recall that you will need to identify the `Local Address` that codespaces is forwarding port 8080 to. From the geoserver admin UI: Click on `stores` and find `osm`. You will need to change the following settings:
- host: postgis
- port: 5432
- schema: import
- user: postgres
- password: postgres
Then: `Save`

Test the data store by looking at layer previews of the `osm` data. To debug whether any issues are with the `osm` (postgis) database or the `osm-lowres` (large geopackage you downloaded), look at Layer Previews of layers in both stores. If everything looks good, open up the `osm:osm` layergroup 

## Deliverable
- `screencap-final.png` - Take a screenshot of the `osm:osm` layer preview zoomed into Reykjavik and include that in a Pull Request to be merged with master.

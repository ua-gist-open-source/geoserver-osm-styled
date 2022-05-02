
# Nicely styling OSM Data in Geoserver
## Background
In previous assignments we downloaded shapefiles extracts from OSM and found them very difficult to style. In a later assignment we used an alternative method for importing `pbf` files using `osm2pgsql` that allowed us to use someone else's symbology to render them nicely in QGIS. In this assignment, we will use yet another method for importing OSM data: `imposm` and someone else's symbology pre-configured for a geoserver usage. This assignment borrows centrally from a single tutorial source but deviates in order to accomodate our docker-based geoserver and postgis installations. We will build on a previous assignment by re-using and re-importing the Iceland OSM data extract.

## Deliverables
- `docker-compose.yml` (updated with your changes)
- `screencap-final.png`

following this tutorial:
https://github.com/geosolutions-it/osm-styles/blob/master/README.md

### 1. Clone the osm-styles repo
Clone [this repo](https://github.com/geosolutions-it/osm-styles.git).

This is a pre-configured copy of a geoserver data directory with styles, layers, stores, and layergroups in a nice OSM style. 
Copy it into a new directory adjacent to your old geoserver data directory from previously but give it a new name. I had previously called mine `/Users/aaryn/gist604b_data/geoserver_data`. For this assignment I'm making a new one named `/Users/aaryn/gist604b_data/geoserver_data_styled`. 

Because your directory will be different than mine, I will refer to it as `$SOME_DIR` throughout this document. You will need to change it wherever you see it.


Copy the `osm-styles` directory that you just downloaded from git into `$SOME_DIR/geoserver_data_styled`. Rename `osm-styles` `data_dir`.

Summary:
Glone the https://github.com/geosolutions-it/osm-styles.git repo to a directory where you will be making a geoserver docker container colume mapping. Rename the `osm-styles` to `data_dir`. 

### 2. Setup the low-res OSM Geopackage

Download the low-resolution OSM Geopackage to the `data_dir/data` directory. This is about 1.9GB so it will take awhile.

[Download](https://www.dropbox.com/s/bqzxzkpmpybeytr/osm-lowres.gpkg?dl=1)

This should be in a `data` directory next to a file named `keepme.txt`. For my example the file would be at `$SOME_DIR/data_dir/data/osm-lowres.gpkg`


### 3. Start up geoserver
Shut down any containers from previous assignments. We will re-use the database but will be starting a new `geoserver` with the new volume mapping. This assignment repo contains a new [`docker-compose.yml`](./docker-compose.yml) that you can use but you will need to update the volume mappings as you did before. In addition, we have turned _off_ sample data and enabled two extensions: [`css-plugin`](https://docs.geoserver.org/latest/en/user/styling/css/install.html) and [`Pregeneralized features`](https://docs.geoserver.org/stable/en/user/data/vector/featurepregen.html). We enable these plugins as per the documentation on the [kartoza/geoserver](https://github.com/kartoza/docker-geoserver#default-installed--plugins) docker hub by adding this environment variable:

```
      - STABLE_EXTENSIONS=css-plugin,feature-pregeneralized-plugin
```

The volume mapping for the geoserver data directory needs to be changed _and it must point to the new data directory we just downloaded from the osm-styles repo_. For my example, what was:
```
      - /Users/aaryn/gist604b_data/geoserver_data/data_dir:/opt/geoserver/data_dir
```
should be changed to:
```
      - /Users/aaryn/gist604b_data/geoserver_data_styled/data_dir:/opt/geoserver/data_dir
```

Launch your `postgis` and `geoserver` containers from the shell with `docker compose up` from the same directory as this `docker-compose.yml` file

*Deliverable:* Add your updated `docker-compose.yml` file to your assignment branch and include it in your final Pull Request.

### 4. [Redundant from previous assignment] Create an `iceland` database

If you haven't already, you will need to create an `iceland` database
```
docker run --network gist604b --entrypoint sh mdillon/postgis -c 'psql -h postgis -U postgres -c "CREATE DATABASE iceland"'
docker run --network gist604b --entrypoint sh mdillon/postgis -c 'psql -h postgis -U postgres -d iceland -c "CREATE EXTENSION postgis"'
docker run --network gist604b --entrypoint sh mdillon/postgis -c 'psql -h postgis -U postgres -d iceland -c "CREATE EXTENSION hstore"'
```

### 5. Download OSM Data for Iceland
You should have downloaded Iceland OSM data in a previous assignment. If not, or you need a new copy, [download `iceland-latest.osm.pbf` from Geofabrik](https://download.geofabrik.de/europe/iceland-latest.osm.pbf)

Save this to your new geoserver `data_dir/data` directory as well. For my example, it is in `/Users/aaryn/gist604b_data/data_dir/data/iceland-latest.osm.pbf`

### 6. Import OSM data

I created a `[Dockerfile](./Dockerfile)` that contains the [imposm3](https://imposm.org/docs/imposm3/latest/tutorial.html) executable. This is the OSM Importer that will import OSM data into the schema that will work with our new styles.


This section serves as an alternate method for [The OSM PostGIS Database](https://github.com/geosolutions-it/osm-styles#the-osm-postgis-database) from the osm-styles README. Essentially, we are going to run `imposm` with:
- volume mapping containing the `imposm/mapping.yml` file from the osm-styles repo
- volume mapping containing the `iceland-latest.osm.pbf` file
- on the `gist604b` network so it can communicate with our postgis instance

#### Bonus experience (the hard option)
Use the given `Dockerfile` and build your own image with `imposm` and use that instead of `aaryno/imposm`:
```
docker build -t imposm .
```

That will build a docker image from the `Dockerfile` in this repo. Now use that to import the osm data:

```
docker run -it --network gist604b -v $SOME_DIR/geoserver_data_styled/data_dir:/opt/geoserver/data_dir aaryno/imposm sh -c "imposm import -mapping /opt/geoserver/data_dir/imposm/mapping.yml -read /opt/geoserver/data_dir/pbf/iceland-latest.osm.pbf -overwritecache -write -connection postgis://postgres:postgres@postgis/iceland"
```

#### The easy option

```
docker run -it --network gist604b -v $SOME_DIR/geoserver_data_styled/data_dir:/opt/geoserver/data_dir aaryno/imposm sh -c "imposm import -mapping /opt/geoserver/data_dir/imposm/mapping.yml -read /opt/geoserver/data_dir/pbf/iceland-latest.osm.pbf -overwritecache -write -connection postgis://postgres:postgres@postgis/iceland"
```

### 7. Fix the `osm` data store in geoserver
Open http://localhost:8280/geoserver. Click on `stores` and find `osm`. You will need to change the following settings:
- host: postgis
- port: 5432
- schema: import
- user: postgres
- password: postgres
Then: `Save`

Test the data store by looking at layer previews of the `osm` data. To debug whether any issues are with the `osm` (postgis) database or the `osm-lowres` (large geopackage you downloaded), look at Layer Previews of layers in both stores. If everything looks good, open up the `osm:osm` layergroup 

## Deliverable
- `docker-compose.yml` (updated with your changes)
- `screencap-final.png` - Take a screenshot of the `osm:osm` layer preview zoomed into Reykjavik and include that in a Pull Request to be merged with master.

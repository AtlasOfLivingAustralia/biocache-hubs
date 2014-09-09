# biocache-hubs [![Build Status](https://travis-ci.org/AtlasOfLivingAustralia/biocache-hubs.svg?branch=master)](http://travis-ci.org/AtlasOfLivingAustralia/biocache-hubs) 

**biocache-hubs** is a Grails plugin that provides the core functionality for the _Atlas of Living Australia_ (ALA) [Occurrence search portal](http://biocache.ala.org.au/search) (Biocache) front-end.

This application/plugin provides a web UI for a back-end service called [**biocache-service**](https://github.com/AtlasOfLivingAustralia/biocache-service) (see [biocache-service API](http://biocache.ala.org.au/ws)) - a full-text search and record retreival for occurrence data records, using JSON data format.

An example Grails application that uses this plugin, is the [**generic-hub**](https://github.com/AtlasOfLivingAustralia/generic-hub) app. There are other implementations listed in the [ALA Github repository](https://github.com/AtlasOfLivingAustralia?query=-hub) (all implementations have a suffix '-hub').

## Getting started
The easiest way to get started is to clone the **generic-hub** project and then modify it to suit your needs. Any functionality that you wish to alter, is achieved by creating a copy of the groovy/GSP/JS/CSS/i18n file of interest, from **biocache-hubs** and placing it in your client app, so that it overrides the plugin version.

E.g. to change the header and footer, create a copy of the file `grails-app/views/layout/generic.gsp` (calling it acme.gsp) and then edit the configuration file to point to this new GSP file: `grails-app/conf/Config.groovy` - change `skin.layout = 'generic'` to the new layout file, e.g. `skin.layout = 'acme'`.

To load and view you own occurrence record data, you'll need to install and run [**biocache-store**](https://github.com/AtlasOfLivingAustralia/biocache-store) and [**biocache-service**](https://github.com/AtlasOfLivingAustralia/biocache-service) and then configure your app to use your local **biocache-service** by adding/editing the line: `biocache.baseUrl = "http://hostname.acme.org/biocache-service/"`.

A full list of the configuration settings (and their default values) are found in `grails-app/conf/defaultConfig.groovy`.

# biocache-hubs [![Build Status](https://travis-ci.org/AtlasOfLivingAustralia/biocache-hubs.svg?branch=master)](http://travis-ci.org/AtlasOfLivingAustralia/biocache-hubs) 

**biocache-hubs** is a Grails plugin that provides the core functionality for the _Atlas of Living Australia_ (ALA) [Occurrence search portal](http://biocache.ala.org.au/search) (Biocache) front-end.

This application/plugin provides a web UI for a back-end service called [**biocache-service**](https://github.com/AtlasOfLivingAustralia/biocache-service) (see [biocache-service API](http://biocache.ala.org.au/ws)) - a full-text search and record retreival for occurrence data records, using JSON data format.

An example Grails application that uses this plugin, is the [**generic-hub**](https://github.com/AtlasOfLivingAustralia/generic-hub) app. There are other implementations listed in the [ALA Github repository](https://github.com/AtlasOfLivingAustralia?query=-hub) (all implementations have a suffix '-hub').

## Versions
The grails2 branch contains the 1.5.x series of the plugin compatible with Grails 2.x

The master branch hosts version 2.x and forward of the plugin compatible with grails 3.x

## Getting started
The easiest way to get started is to clone the **generic-hub** project and then modify it to suit your needs. Any functionality that you wish to alter, is achieved by creating a copy of the groovy/GSP/JS/CSS/i18n file of interest, from **biocache-hubs** and placing it in your client app, so that it overrides the plugin version.

E.g. to change the header and footer, create a copy of the file `grails-app/views/layout/generic.gsp` (calling it acme.gsp) and then edit the configuration file to point to this new GSP file: `grails-app/conf/Config.groovy` - change `skin.layout = 'generic'` to the new layout file, e.g. `skin.layout = 'acme'`.

To load and view you own occurrence record data, you'll need to install and run [**biocache-store**](https://github.com/AtlasOfLivingAustralia/biocache-store) and [**biocache-service**](https://github.com/AtlasOfLivingAustralia/biocache-service) and then configure your app to use your local **biocache-service** by adding/editing the line: `biocache.baseUrl = "http://hostname.acme.org/biocache-service/"`.

A full list of the configuration settings (and their default values) are found in `src/main/groovy/au/org/ala/biocache/hubs/defaultConfig.groovy`.

## Grails 3

Starting with version 1.7 biocache-hubs has been migrated to run on Grails 3 and Java 8

If you have deployed biocache-hubs plugin version 1.4.x or earlier in your own hub then you need to follow the following points to bring that hub up to date to use the latest version of biocache-hubs

* The minimum version of Java is 8
* You have to use the latest Grails 3.1.x 
Use these as reference: 
    * http://docs.grails.org/3.2.11/guide/upgrading.html#upgrading2x
    * https://docs.grails.org/3.0.x/guide/upgrading.html
* biocache-hubs now uses ala-auth 3.x, see this [guide](https://github.com/AtlasOfLivingAustralia/ala-auth-plugin/wiki/1.x-Migration-Guide) for configuration changes
* Grails 3 no longer supports resources pipeline, You will have to migrate resources settings to [Asset pipeline plugin configuration](http://www.asset-pipeline.com/manual/#grails3)
* Following from the above, your hub should use at the very least these two assets: `hubCore.css` and `hubCore.js`. The easiest way is to add them to the head section of your hub layouts
    
    An example of this can be found [here](https://github.com/AtlasOfLivingAustralia/ala-hub/blob/c6c999d7e87de985bfc65e1fe6fe5cd13396212f/grails-app/views/layouts/generic.gsp#L9-L10)
   In this case, alaBs.css and alaBs.js source the required dependencies:
   * https://github.com/AtlasOfLivingAustralia/ala-hub/blob/77ad912b6007afb21e5ee9d46cd068ba2040eb9f/grails-app/assets/stylesheets/alaBs.css#L11
   * https://github.com/AtlasOfLivingAustralia/ala-hub/blob/c6c999d7e87de985bfc65e1fe6fe5cd13396212f/grails-app/assets/javascripts/alaBs.js#L11
   


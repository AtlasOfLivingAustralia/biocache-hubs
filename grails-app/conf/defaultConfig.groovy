//  Copyright (C) 2014 Atlas of Living Australia
//  All Rights Reserved.
//
//  The contents of this file are subject to the Mozilla Public
//  License Version 1.1 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of
//  the License at http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS
//  IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
//  implied. See the License for the specific language governing
//  rights and limitations under the License.
//
//grails.resources.work.dir=/data/cache/hubs
//
// CAS properties - may be omitted for non-ALA deployments
//
//security.cas.appServerName = "http://dev.ala.org.au:8080"
//security.cas.casServerName = 'https://auth.ala.org.au'
//security.cas.uriFilterPattern = '/admin, /admin/.*'
//security.cas.authenticateOnlyIfLoggedInPattern = "/occurrences/(?!.+userAssertions|facet.+).+,/explore/your-area"
//security.cas.uriExclusionFilterPattern = '/images.*,/css.*,/js.*'
//security.cas.loginUrl = 'https://auth.ala.org.au/cas/login'
//security.cas.logoutUrl = 'https://auth.ala.org.au/cas/logout'
//security.cas.casServerUrlPrefix = 'https://auth.ala.org.au/cas'
//security.cas.bypass = false // set to true for non-ALA deployment
//security.cas.contextPath = "/generic-biocache-hub" //"/${appName}"
//security.cas.debugWebXml = true
auth.admin_role = "ROLE_ADMIN"
serverName = 'http://dev.ala.org.au:8080'

// skin settings
organisation.baseUrl = "http://www.ala.org.au"
skin.layout = "generic"
skin.fluidLayout = "true"
skin.orgNameLong = "Generic Portal"
skin.orgNameShort = "Generic"
skin.attribution = ""
skin.useAlaSpatialPortal = false
skin.useAlaBie = false
skin.useAlaImageService = false
skin.taxaLinks.baseUrl = "" // "http://bie.ala.org.au/species/" // 3rd party species pages. Leave blank for no links
skin.taxaLinks.identifier = "guid"  // "guid" or "name". Only used if skin.useAlaBie = false TODO: not implemented

// web services
bie.baseUrl = "http://bie.ala.org.au"
bieService.baseUrl = "http://bie.ala.org.au/ws"
//bie.autocompleteHints.fq = "kingdom:Plantae"  // optional
collectory.baseUrl = "http://collections.ala.org.au"
logger.baseUrl = "http://logger.ala.org.au/service"
biocache.apiKey = "api-key-to-use"
biocache.baseUrl = "http://biocache.ala.org.au/ws"
biocache.queryContext = "" // datahub uuid - e.g. ozcam  = " data_hub_uid:dh1 || avh = data_hub_uid:dh2"
biocache.downloads.extra = "dataResourceUid,dataResourceName.p"
biocache.ajax.useProxy = false
//biocache.groupedFacetsUrl = "${biocache.baseUrl}/search/grouped/facets" // optional - define in hub only
collections.baseUrl = "http://collections.ala.org.au"
useDownloadPlugin = ""

// images
images.baseUrl = "http://images.ala.org.au"
images.viewerUrl = "http://images.ala.org.au/image/viewer?imageId="
images.metadataUrl = "http://images.ala.org.au/image/details?imageId="

sightings.baseUrl = "http://sightings.ala.org.au"

// For sandbox environment
//spatial.params = "&dynamic=true&ws=http%3A%2F%2Fsandbox.ala.org.au%2Fhubs-webapp&bs=http%3A%2F%2Fsandbox.ala.org.au%2Fbiocache-service"
spatial.baseUrl = "http://spatial.ala.org.au/"
layersservice.baseUrl = "http://spatial.ala.org.au/ws"
spatial.params = ""
test.var = "test"

clubRoleForHub = "ROLE_ADMIN"
// whether map or list is the default tab to show - empty for list and "mapView" for map
defaultListView = "" //  'mapView' or 'listView'
dataQualityChecksUrl = "https://docs.google.com/spreadsheet/pub?key=0AjNtzhUIIHeNdHJOYk1SYWE4dU1BMWZmb2hiTjlYQlE&single=true&gid=0&output=csv"
dwc.exclude = "dataHubUid,dataProviderUid,institutionUid,year,month,day,modified,left,right,provenance,taxonID,preferredFlag,outlierForLayers,speciesGroups,associatedMedia,images,userQualityAssertion,speciesHabitats,duplicationType,taxonomicIssues,subspeciesID,nameMatchMetric,sounds"

exploreYourArea.lat = "-35.0"
exploreYourArea.lng = "149.0"
exploreYourArea.location = "Canberra, ACT"

facets.includeDynamicFacets = "false" // sandbox
facets.limit = "100"
facets.customOrder = ""
facets.exclude = "dataHubUid,year,day,modified,left,right,provenance,taxonID,preferredFlag,outlierForLayers,speciesGroups,associatedMedia,images,userQualityAssertion,speciesHabitats,duplicationType,taxonomicIssues,subspeciesID,nameMatchMetric,sounds"
facets.hide = "genus,order,class,phylum,kingdom,raw_taxon_name,rank,interaction,raw_state_conservation,biogeographic_region,year,institution_uid,collection_uid"
facets.include = "establishment_means,user_assertions,assertion_user_id,name_match_metric,duplicate_type,alau_user_id,raw_datum,raw_sex,life_stage,elevation_d_rng,identified_by,species_subgroup,cl1048"
facets.cached = "collection_uid,institution_uid,data_resource_uid,data_provider_uid,type_status,basis_of_record,species_group,loan_destination,establishment_means,state_conservation,state,cl1048,cl21,cl966,country,cl959"

map.cloudmade.key = "BC9A493B41014CAABB98F0471D759707"
map.defaultFacetMapColourBy = "basis_of_record"
map.pointColour = "df4a21"
map.zoomOutsideScopedRegion = true
map.defaultLatitude
map.defaultLongitude
map.defaultZoom
// 3rd part WMS layer to show on maps. TODO: Allow multiple overlays
map.overlay.url
map.overlay.name
map.minimal.url = "http://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png"
map.minimal.attr = "Map data &copy; <a href='http://www.openstreetmap.org/copyright'>OpenStreetMap</a>, imagery &copy; <a href='http://cartodb.com/attributions'>CartoDB</a>"
map.minimal.subdomains = "abcd"
//map.mapbox.id = "nickdos.kf2g7gpb" // http://mapbox.com/ Registered by Nick - free to use so anyone can create a new one and add it here
//map.mapbox.token = "pk.eyJ1Ijoibmlja2RvcyIsImEiOiJ2V2dBdEg0In0.Ep2VyMOaOUnOwN1ZVa9uyQ"

suppressIssues = "" // "missingCoordinatePrecision"
sensitiveDataset.list = ""

table.displayDynamicProperties = false
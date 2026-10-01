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

dataquality.enabled = false
dataquality.baseUrl = 'https://data-quality-service-test.ala.org.au'
dataquality.recordCountCacheSpec = 'expireAfterWrite=1d'
dataquality.prefkey = 'dqUserProfile'
dataquality.expandKey = 'dqDetailExpand'

// Lookup table for licences. This lookup falls back to OccurrenceTagLib.parseCcByLicense when no match or img is found.
license.lookup = [
    [pattern: '^CC0$', label: 'CC0',
     img: 'https://licensebuttons.net/p/zero/1.0/88x31.png',
     url: 'https://creativecommons.org/publicdomain/zero/1.0/'],
    [pattern: '^PDM$', label: 'Public Domain Mark',
     img: 'https://licensebuttons.net/p/mark/1.0/88x31.png',
     url: 'https://creativecommons.org/publicdomain/mark/1.0/'],
    [pattern: '.*', label: '', img: '', url: '']
]

// Settings used by the generic 'CC-BY...' pattern-matcher (parseCcByLicense) to build
// licensebuttons.net/creativecommons.org URLs for values not explicitly overridden above.
// Version used when a value has no version number at all (e.g. 'CC-BY', 'CC-BY-NC').
license.ccBy.defaultVersion = '4.0'
// Version assumed when a jurisdiction is given but no version (e.g. 'CC-BY-Aus').
// Ported (country-specific) legal code has historically only existed for 3.0.
license.ccBy.portedVersion = '3.0'
// Aliases for jurisdictions (case-insensitive) to normalise values like 'CC-BY-AU' and 'CC-BY-Australia' to the canonical 'au' used in licensebuttons.net/creativecommons.org URLs.
license.ccBy.jurisdictions = [
    au           : 'au',
    aus          : 'au',
    australia    : 'au',
    nz           : 'nz',
    nzl          : 'nz',
    newzealand   : 'nz',
    int          : '',
    intl         : '',
    international: '',
    unported     : ''
]

// skin settings
organisation.baseUrl = "https://www.ala.org.au"
skin.layout = "generic"
skin.fluidLayout = "true"
skin.orgNameLong = "Generic Portal"
skin.orgNameShort = "Generic"
skin.attribution = ""
skin.useAlaSpatialPortal = false
skin.useAlaBie = false
skin.useAlaImageService = false
skin.taxaLinks.baseUrl = "" // "https://bie.ala.org.au/species/" // 3rd party species pages. Leave blank for no links
skin.taxaLinks.identifier = "guid"  // "guid" or "name". Only used if skin.useAlaBie = false TODO: not implemented
skin.exploreUrl = "${serverName}"

// web services
bie.baseUrl = "https://bie.ala.org.au"
bieService.baseUrl = "https://bie-ws.ala.org.au/ws"
//bie.autocompleteHints.fq = "kingdom:Plantae"  // optional
collectory.baseUrl = "https://collections.ala.org.au"
logger.baseUrl = "https://logger.ala.org.au/service"
biocache.apiKey = "not-your-api-key-to-use"
biocache.baseUrl = "https://api.ala.org.au/occurrences"
biocache.queryContext = "" // datahub uuid - e.g. ozcam  = " data_hub_uid:dh1 || avh = data_hub_uid:dh2"
biocache.downloads.extra = "dataResourceUid,dataResourceName.p"
biocache.ajax.useProxy = false
biocache.indexedFieldsUrl = "${biocache.baseUrl}/index/fields"
//biocache.groupedFacetsUrl = "${biocache.baseUrl}/search/grouped/facets" // optional - define in hub only
collections.baseUrl = "https://collections.ala.org.au"
alerts.baseUrl = "https://alerts.ala.org.au"
speciesList.baseURL = "https://lists.ala.org.au"
useDownloadPlugin = ""

// for images-client-plugin
image.baseUrl = "https://images.ala.org.au"

// images
images.baseUrl = "https://images.ala.org.au"
images.viewerUrl = "https://images.ala.org.au/image/viewer?imageId="
images.metadataUrl = "https://images.ala.org.au/image/details?imageId="

help.flagIssueUrl = "https://support.ala.org.au/support/solutions/articles/6000262125-flagging-an-issue-with-a-record"

dataResourceUuid.alaSightings = "dr364"
dataResourceUuid.iNaturalist = "dr1411"
dataResourceUuid.flickr = "dr360"
sightings.baseUrl = "https://biocollect.ala.org.au"
iNaturalist.baseUrl = "https://inaturalist.ala.org.au"

// For sandbox environment
//spatial.params = "&dynamic=true&ws=http%3A%2F%2Fsandbox.ala.org.au%2Fhubs-webapp&bs=http%3A%2F%2Fsandbox.ala.org.au%2Fbiocache-service"
spatial.baseUrl = "https://spatial.ala.org.au/"
layersservice.baseUrl = "https://spatial.ala.org.au/ws"
spatial.params = ""
test.var = "test"
// used to link temporary data resources back to an originating sandbox.
sandbox.uploadSource=''
advancedTaxaField = "taxa" // used in advanced form for the 4 taxa query inputs
alerts.myannotation.enabled = false
clubRoleForHub = "ROLE_ADMIN"
// whether map or list is the default tab to show - empty for list and "mapView" for map
defaultListView = "" //  'mapView' or 'listView'
dataQualityChecksUrl = "https://docs.google.com/spreadsheet/pub?key=0AjNtzhUIIHeNdHJOYk1SYWE4dU1BMWZmb2hiTjlYQlE&single=true&gid=0&output=csv"
dwc.exclude = "dataHubUid,dataProviderUid,institutionUid,year,month,day,modified,left,right,provenance,taxonID,preferredFlag,outlierForLayers,speciesGroups,associatedMedia,images,userQualityAssertion,speciesHabitats,duplicationType,taxonomicIssues,subspeciesID,nameMatchMetric,sounds,datasetName,fieldNumber"

exploreYourArea.lat = "-35.0"
exploreYourArea.lng = "149.0"
exploreYourArea.location = "Canberra, ACT"
exploreYourArea.zoomLevels = [ 1: 14, 5: 12, 10: 11, 50: 9 ]

facets.limit = "100"
facets.max = "40"
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
map.outlineDots
// 3rd part WMS layer to show on maps. TODO: Allow multiple overlays
map.overlay.url
map.overlay.name
map.minimal.vectorTileUrl = "https://basemaps.cartocdn.com/gl/positron-gl-style/style.json"
map.minimal.url = "https://basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}.png"
map.minimal.attr = "<a href='https://carto.com/' target='_blank' rel='noopener' class='carto-logo-link' title='CARTO'><svg xmlns='http://www.w3.org/2000/svg' width='56' height='22' viewBox='0 0 230 90' class='carto-logo' aria-label='CARTO'><g fill='#162945' fill-rule='evenodd'><circle cx='185' cy='45' r='45' opacity='.1'/><path d='M14.8 59.954c6.315 0 9.964-2.747 12.67-6.478l-5.986-4.264c-1.722 2.09-3.485 3.485-6.478 3.485-4.018 0-6.847-3.362-6.847-7.667v-.082c0-4.182 2.828-7.626 6.846-7.626 2.747 0 4.633 1.353 6.273 3.362l5.985-4.633c-2.542-3.484-6.314-5.944-12.177-5.944C6.396 30.106 0 36.666 0 45.03v.082c0 8.57 6.6 14.842 14.8 14.842zm26.212-.574h8.323l2.05-5.166h11.11l2.05 5.166h8.53l-12.22-28.905H53.19L41.01 59.38zm12.71-11.357l3.24-8.118 3.197 8.118H53.72zm34.84 11.357h7.954v-8.692h3.526l5.78 8.692h9.144l-6.847-10.004c3.566-1.517 5.903-4.428 5.903-8.856v-.082c0-2.83-.86-5.002-2.542-6.683-1.926-1.927-4.96-3.075-9.347-3.075h-13.57v28.7zm7.954-14.924v-6.93h5.248c2.624 0 4.305 1.15 4.305 3.445v.083c0 2.09-1.6 3.403-4.265 3.403h-5.29zm41.236 14.924V37.65h-8.57v-6.97h25.134v6.97h-8.61v21.73h-7.954zM185 60c-8.284 0-15-6.716-15-15 0-8.284 6.716-15 15-15 8.284 0 15 6.716 15 15 0 8.284-6.716 15-15 15z'/></g></svg></a> &copy; <a href='https://www.openstreetmap.org/copyright' target='_blank' rel='noopener'>OpenStreetMap</a> contributors, &copy; <a href='https://carto.com/attribution/' target='_blank' rel='noopener'>CARTO</a>"
map.minimal.subdomains = "abcd"
//map.mapbox.id = "nickdos.kf2g7gpb" // https://mapbox.com/ Registered by Nick - free to use so anyone can create a new one and add it here
//map.mapbox.token = "pk.eyJ1Ijoibmlja2RvcyIsImEiOiJ2V2dBdEg0In0.Ep2VyMOaOUnOwN1ZVa9uyQ"


suppressIssues = "" // "missingCoordinatePrecision"
sensitiveDataset.list = ""

table.displayDynamicProperties = false

geocode.region = "AU"

geopip.database.path="/data/${grails.util.Metadata.current.getApplicationName()}/config/GeoLite2-City.mmdb"

fieldguide.url="https://fieldguide.ala.org.au"
stateConservationListPath = [:] // to prevent NPE - set in ext config
// example: stateConservationListPath.NewSouthWales = "/speciesListItem/list/dr650"
alwaysshow.imagetab = false

facets.defaultSelected = "data_resource_uid,taxon_name,year,multimedia"

// User properties are stored by "userdetails" or "biocache".
// This is required when using AWS Cognito with userdetails (more or less).
userproperties.provider="userdetails"

mapdownloads {
    baseLayers {
        default_layer {
            name = 'world'
            i18nCode = 'baselayer.world'
            displayName = 'Simple World Outline'
        }
    }
    baseMaps {
//        hybrid {
//            i18nCode = 'basemap.hybrid'
//            name = 'hybrid'
//            displayName = 'Google Hybrid'
//        }
//        satellite {
//            i18nCode = 'basemap.satellite'
//            name = 'satellite'
//            displayName = 'Google Satellite'
//        }
//        roadmap {
//            i18nCode = 'basemap.hybrid'
//            name = 'roadmap'
//            displayName = 'Google Road Map'
//        }
    }
}

events {
    enabled = true
    graphql = "https://api.test.ala.org.au/event/graphql"
    eventUrl = "https://events.test.ala.org.au/?view=EVENTS&eventHierarchy="
}

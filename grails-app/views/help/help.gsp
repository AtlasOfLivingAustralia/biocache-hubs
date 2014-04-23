%{--
  - Copyright (C) 2014 Atlas of Living Australia
  - All Rights Reserved.
  -
  - The contents of this file are subject to the Mozilla Public
  - License Version 1.1 (the "License"); you may not use this file
  - except in compliance with the License. You may obtain a copy of
  - the License at http://www.mozilla.org/MPL/
  -
  - Software distributed under the License is distributed on an "AS
  - IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
  - implied. See the License for the specific language governing
  - rights and limitations under the License.
  --}%
<%--
  Created by IntelliJ IDEA.
  User: dos009@csiro.au
  Date: 23/04/2014
  Time: 3:31 PM
  To change this template use File | Settings | File Templates.
--%>

<%@ page contentType="text/html;charset=UTF-8" %>
<g:set var="hostName" value="${request.requestURL.replaceFirst(request.requestURI, '')}"/>
<g:set var="fullName" value="${grailsApplication.config.skin.orgNameLong}"/>
<g:set var="shortName" value="${grailsApplication.config.skin.orgNameShort}"/>
<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta name="layout" content="${grailsApplication.config.skin.layout}"/>
    <meta name="section" content="help"/>
    <title>${shortName} - Help</title>
    <r:require modules="help"/>
</head>

<body>
<div id="toc">&nbsp;</div>

<div id="help_content" >
<h1>${shortName} Help</h1>
<h2>
    Registration and login
</h2>
<p>
    No registration or login is needed to access or download data from ${fullName} . All data, except for data of certain taxa that are
    sensitive for conservation or biosecurity reasons, is accessible to everyone. We do, however, encourage all users to register, as registration makes some
    extra features available. You need to be logged in to report an issue with an ${shortName} record and to sign up for e-mail alerts. Also, ${shortName} remembers some of your
    preferences during your session and, if you log in, stores a cookie on your machine, so your session lasts until the cookie expires or is deleted.
    Registrations for ${shortName} are no longer vetted. ${shortName} is part of the Atlas of Living Australia (ALA), so if you already have an ALA user account, you don't need
    to register separately for ${shortName}, but can log in using your ALA account details.
</p>
<h2>
    Search
</h2>
<p>
    There are five main search options for querying ${shortName} data. The <span class="feature">Quick search</span> allows you to quickly perform a search using a single search term. The <span class="feature">Advanced
search</span> allows you to perform a more structured query using one or more criteria. The <span class="feature">Batch name search</span> and <span class="feature">Batch catalogue number search</span> allow you to query
by multiple taxon names and multiple catalogue numbers respectively. The <span class="feature">Shapefile search</span> allows you to query by a polygon defined in a shapefile.
</p>
<p>
    Information on how the different search options work is provided below. See the <a href="data.html"><span class="feature">Data</span></a> page for descriptions of the data associated with each of the query
terms.
</p>
<h3>
    Quick search
</h3>
<p>
    The <span class="feature">Quick search</span> first attempts to match the search term against a standard list of botanical names and common names. If no matches are found, a match will
be attempted against the taxon names provided with the specimen records. If there is still no match, a full text search will be performed against the
following fields: <a href="data.html#herbarium"><span class="feature">Herbarium name</span></a>, <a href="data.html#herbarium_code"><span class="feature">Herbarium
code</span></a>, <a href="data.html#catalogue_number"><span class="feature">Catalogue number</span></a>, <a href="data.html#collector"><span class="feature">Collector</span></a>,
    <a href="data.html#determiner"><span class="feature">Determiner</span></a> and <a href="data.html#collecting_notes"><span class="feature">Collecting notes</span></a>.
</p>
<h3>
    Advanced search
</h3>
<p>
    The <span class="feature">Advanced search</span> allows you to perform a structured query using one or more criteria. The data fields you can query on are explained in some detail on
the <a href="data.html"><span class="feature">Data</span></a> page.
</p>
<h4>
    Taxon name
</h4>
<p>
    The <span class="feature">Taxon name search</span> attempts to match the search term against a standard list of botanical names and common names. If no matches are found, a match will
be attempted against the taxon names provided with the specimen records (<a href="data.html#taxon_names_in_${shortName}"><span class="feature">Taxon name (provided)</span></a>). The taxon name search term can be combined with other
search terms in the <span class="feature">Advanced search</span>.
</p>
<p>
    Taxon names can be botanical names of any rank, or common names. Common names are not provided with the ${shortName} data and are not a reliable means of querying
    ${shortName} records.
</p>
<p>
    You can enter up to four taxon names in the <span class="feature">Advanced search</span>. If you want to query on more than four taxon names at the one time, use the <span class="feature">Batch name search</span>;
you can then use the facets on the results page to add more search terms to your query.
</p>
<h4>
    Full text search
</h4>
<p>
    Unlike the other items in the <span class="feature">Advanced search</span> tab, <span class="feature">Full text search</span> will try
to locate the entered string in a number of fields. These include <a href="data.html#herbarium"><span class="feature">Herbarium name</span></a>,
    <a href="data.html#herbarium_code"><span class="feature">Herbarium code</span></a>, <a href="data.html#catalogue_number"><span class="feature">Catalogue number</span></a>,
    <a href="data.html#collector"><span class="feature">Collector</span></a>,
    <a href="data.html#determiner"><span class="feature">Determiner</span></a> and <a href="data.html#collecting_notes"><span class="feature">Collecting notes</span></a>.
</p>
<p>
    The <span class="feature">Full text search</span> will match the parts of the search string to entire words, but you can add a wildcard ('*') to the last part of the string to match to
the start of words. By default, the <span class="feature">Full text search</span> will split the search string into its parts and will match to strings where the matched words are
separated from each other by text or are in a different order than the parts of the search string. To avoid this behaviour you can enclose the search
string in double quotes. Wildcards in quoted strings will be ignored. Individual words in a search string will be matched to pluralised forms of the word.
For example, 'cow' will return records with 'cows' in it.
</p>
<h3>
    Batch name search
</h3>
<p>
    The <span class="feature">Batch name search</span> allows you to perform a query against a list of taxon names. Each taxon name needs to be entered on a separate line in the query box.
</p>
<p>
    The list of names entered in the <span class="feature">Batch name search</span> are matched against the unprocessed taxon names provided with the specimen records (<span class="feature">Taxon name
(provided)</span>). The <span class="feature">Taxon name (provided)</span> for infraspecific taxa may include authors after the species name, and may use inconsistent abbreviations for the
infraspecific rank ('subsp.', 'ssp.' etc.). Because of this, you will get the most predictable results from a batch name search if you don't include author
names or names of infraspecific taxa in your list of taxon names. You can then further refine your results using the facets, or by downloading the data and
removing any unwanted records.
</p>
<p>
    Unlike the single taxon name searches, the <span class="feature">Batch name search</span> only queries on <a href="data.html#taxon_names_in_${shortName}"><span class="feature">Taxon name (provided)</span></a>
    and will not include synonyms in the results. Therefore, for complete results, all known synonyms need to be included in the batch of names.
</p>
<div class="screenshot">
    <img
            src="${request.contextPath}/static/images/help/screenshot_batch_name_search.jpg"
            alt="Screen capture Batch name search"
            width="241"
            height="167"
    />
</div>
<h3>
    Batch catalogue number search
</h3>
<p>
    The <span class="feature">Batch catalogue number search</span> allows you to perform a query against a list of catalogue numbers. Each catalogue number needs to be entered on a
separate line in the query box. Catalogue numbers must be formatted exactly as they are stored in ${shortName}; see the <a href="data.html#catalogue_number"><span class="feature">Data page</span></a>
    for a summary of the catalogue number formats used by different herbaria.
</p>
<div class="screenshot">
    <img
            src="${request.contextPath}/static/images/help/screenshot_batch_catalogue_number_search.jpg"
            alt="Screen capture Batch catalogue number search"
            width="191"
            height="186"
    />
</div>
<h3>
    Shapefile search
</h3>
<p>
    The <span class="feature">Shapefile search</span> allows you to upload an ESRI shapefile and perform a polygon search. Please note that a search is performed only on the first polygon
encountered in the shapefile. You will need a tool like OGR Info to find out which polygon is on top. There is also a good chance that the area of interest
consists of more than one polygon in the shapefile. A more comprehensive polygon search can be found in the
    <a href="http://spatial.ala.org.au/">ALA spatial portal</a>.
</p>
<h3>
    Auto-complete suggestions
</h3>
<p>
    In the <span class="feature">Quick search</span> and the <span class="feature">Taxon name</span> input in the <span class="feature">Advanced search</span>, when you start typing, a drop-down list with suggestions for taxon names will appear.
These names come from the ALA name list and, although they are only names of plants, fungi and algae, do not necessarily correspond with names in ${shortName}. The
correspondence between names on the ALA name list and names in ${shortName} will improve when the National Species Lists have been completed.
</p>
<h2>
    Results
</h2>
<p>
    There are three main options for viewing the results of a query: as a list of records, as a distribution map, and as a series of charts that display
    certain facets of the results. You can narrow down the results of your initial search by selecting values from the facets in the <span class="feature">Refine results</span> menu
on the left-hand side of the page, and the results displayed in the records, map and charts tab will be updated accordingly.
</p>
<h3>
    Refine results
</h3>
<p>
    The facets in the <span class="feature">Refine results</span> menu can be used to apply additional search criteria to your result set. Only the first three values will be listed
under each of the facet titles on the Results page, but you can view all values in a pop-up window by clicking on 'choose more'. If there are more than 100
values in the facet, only the first 100 values will initially be loaded, but the next 100 values will load when you scroll to the bottom of the window. By
clicking on the column headers you can order the values in a facet alphabetically by value or by decreasing number of records. You can filter by a single
value by clicking on that value. You can also use the checkboxes to select up to 15 values and either include only records with the selected values in the
results or exclude those records from the results.
</p>
<div class="screenshot">
    <img
            src="${request.contextPath}/static/images/help/screenshot_facet_pop-up_window.jpg"
            alt="Screen capture facet pop-up window"
            width="516"
            height="568"
    />
</div>
<p>
    All filters that have been used will be listed under <span class="feature">Current filters</span>. You can turn individual filters off by clicking on the '[X]' following the filter.
</p>
<img
        src="${request.contextPath}/static/images/help/screenshot_current_filter.jpg"
        alt="Screen capture current filter"
        width="309"
        height="117"
/>
<p>
    By default, most of the available facets are displayed in the sidebar. You can choose which facets you want to display from the drop-down list under
    <span class="feature">Refine results</span>. Your choice will be remembered during the session.
</p>
<div class="screenshot">
    <img
            src="${request.contextPath}/static/images/help/screenshot_facets_drop-down.jpg"
            alt="Screen capture facet selection drop-down window"
            width="630"
            height="398"
    />
</div>
<h3>
    Records tab
</h3>
<p>
    The <span class="feature">Records</span> tab provides a summary of each specimen record. The most recently published (or edited) records will appear at the top of the list (note that
these are not necessarily the most recently collected specimens). Clicking on an individual record will open the Record detail page, which provides all
available data for that record.
</p>
<h4>
    Downloads
</h4>
<p>
    You may download a spreadsheet of the records in your search results, or a species checklist of unique taxon
    names (<a href="data.html#taxon_names_in_${shortName}"><span class="feature">Taxon name (processed)</span></a>) in the results.
</p>
<div class="screenshot">
    <img
            src="${request.contextPath}/static/images/help/screenshot_data_downloads.jpg"
            alt="Screen capture data download window"
            width="458"
            height="244"
    />
</div>
<p>
    The column labels in the CSV export are shared with other ALA applications and are not always the same as elsewhere
    in ${shortName}. A table with the column names in the CSV output and their equivalents in ${shortName} can be found in the
    <a href="downloadfields.html">Download fields</a> page.
</p>
<h4>
    Alerts
</h4>
<p>
    You can use the Alerts function to be notified when new records that match your search criteria are made available in ${shortName}, or when new user-contributed
    annotations are made to records in your search results. You need to be logged in to subscribe to e-mail alerts.
</p>
<div class="screenshot">
    <img
            src="${request.contextPath}/static/images/help/screenshot_alerts.jpg"
            alt="Screen capture ALA alert e-mails"
            width="258"
            height="176"
    />
</div>
<p>
    You can choose to receive alerts on a monthly, weekly, daily or hourly basis. In addition to alerts that relate to your search, you can choose to receive
    alerts when new records, annotations or images of any kind are added to the ALA.
</p>
<div class="screenshot">
    <img
            src="${request.contextPath}/static/images/help/screenshot_alert_page.jpg"
            alt="Screen capture ALA alert page"
            width="617"
            height="151"
    />
</div>
<h3>
    Map tab
</h3>
<h4>
    Map symbols
</h4>
<p>
    You can change the size of the dots by using the Size slider. The dots can be differentially coloured by choosing one of the facets from the <span class="feature">Colour by</span>
    drop-down list. Dots for facet values can be displayed or hidden by using the checkboxes in the <span class="feature">Legend</span> in the top righthand corner of the map.
</p>
<p>
    You can click on points on the map to view details of the corresponding specimen record.
</p>
<h4>
    Overlays
</h4>
<p>
    You can select one of the following environmental layers from the <span class="feature">Environmental layer</span> drop-down list:
</p>
<ul>
    <li>
        <a href="http://spatial.ala.org.au/layers/more/ibra_merged">Interim Biogeographic Regionalisation of Australia (IBRA)</a>
    </li>
    <li>
        <a href="http://spatial.ala.org.au/layers/more/landuse">Catchment-scale land use (ALUM secondary class)</a>
    </li>
    <li>
        <a href="http://spatial.ala.org.au/layers/more/rh2mean">Mean annual relative humidity (%)</a>
    </li>
    <li>
        <a href="http://spatial.ala.org.au/layers/more/rain_ann">Mean annual rainfall (mm)</a>
    </li>
    <li>
        <a href="http://spatial.ala.org.au/layers/more/maxtm">Mean annual maximum temperature (°C)</a>
    </li>
    <li>
        <a href="http://spatial.ala.org.au/layers/more/fire_frq">Fire frequency - number of fires between 1997 and 2008 for each cell</a>
    </li>
    <li>
        <a href="http://spatial.ala.org.au/layers/more/aus1">States and territories (including coastal waters) - Australian marine maritime boundaries</a>
    </li>
    <li>
        <a href="http://spatial.ala.org.au/layers/more/substrate_geolrngeage">Geological age range (million years) </a>
    </li>
    <li>
        <a href="http://spatial.ala.org.au/layers/more/lith_geologicalunitpolygons1m">Surface geology of Australia (1:1,000,000 scale, 2010 edition)</a>
    </li>
    <li>
        <a href="http://spatial.ala.org.au/layers/more/aspect">Aspect (degree)</a>
    </li>
    <li>
        <a href="http://spatial.ala.org.au/layers/more/elevation">Elevation (metres above sea level)</a>
    </li>
    <li>
        <a href="http://spatial.ala.org.au/layers/more/landcover">Vegetation cover, based on integrated vegetation (class)</a>
    </li>
</ul>
<p>
    The legend for the selected environmental layer, if it has one, will appear below the map.
</p>
<h4>
    View in Spatial portal
</h4>
<p>
    Clicking on the 'View in Spatial Portal' button will open your result set in the ALA Spatial Portal. The Spatial portal has a wide range of tools for
    performing detailed spatial analysis of your query results (you can also upload your own data set for analysis). A
    <a href="http://www.ala.org.au/spatial-portal-help/getting-started/">guide for using the spatial analysis tools</a>
    is available on the ALA website.
</p>
<h4>
    Download map
</h4>
<p>
    You can download a high-resolution map by clicking on the 'Download map' button. In the pop-up window you can select the format, size and resolution of the
    map; the base layer; and the size, colour and opacity of the map symbols.
</p>
<div class="screenshot">
    <img
            src="${request.contextPath}/static/images/help/screenshot_download_map.jpg"
            alt="Screen capture Download map window"
            width="467"
            height="297"
    />
</div>
<h3 id="charts">
    Charts
</h3>
<p>
    The <span class="feature">Charts</span> tab displays the query results as a series of charts based on a selection of facets. You can filter your results by clicking on a segment in a
pie chart or a bar in a bar graph. Clicking on a segment in the pie chart for Taxon, which is the first chart, will not filter your results, but will return a pie chart for the next lower taxonomic level.
</p>
<h2>
    Record detail
</h2>
<p>
    The <span class="feature">Record detail</span> page displays comprehensive specimen data for a single record. The content of the different fields is described on the Data
page. Date loaded (which appears under the location map) indicates the date the record was provided to the ALA BioCache. Date loaded will change if the
specimen record has been edited at the source institution. The Date last processed indicates the date that the record was last changed within the ALA
BioCache. This may happen, for instance, when there is a change in the backbone taxonomy or the Sensitive Data Service, or when new environmental layers
are loaded, and thus doesn't represent any change to the specimen data held by the source institution.
</p>
<p>
    Note that any common names listed after the taxon name at the top of the page come from the name lists used by ALA and are not provided with the records.
</p>
<p>
    In addition to the specimen data from the herbaria, you can view additional political boundaries and extensive environmental sampling
    data that relates to the collecting locality.
</p>
<h3>
    Data validation issues
</h3>
<p>
    When ${shortName} data is uploaded into the ALA BioCache, a range of quality assurance checks are performed and potential data issues are flagged. A summary of the
    data issues is listed on the <span class="feature">Record detail</span> page under the <span class="feature">Data validation issues</span> heading.
The <a href="data.html#data_issues"><span class="feature">Data issues</span></a> section of the <span class="feature">Data</span> page describes the validation issues associated
with ${shortName} data.
</p>
<h3>
    Flag an issue
</h3>
<p>
    Users can flag potential issues with specimen records by using the <span class="feature">Flag an issue</span> feature on the <span class="feature">Record detail</span> page.
Data issues detected during processing or flagged by users are available as a facet on the <span class="feature">Results</span> page, and can be used to narrow down your search results.
</p>
<div class="screenshot">
    <img
            src="${request.contextPath}/static/images/help/screenshot_flag_an_issue.jpg"
            alt="Screen capture Flag an issue"
            width="360"
            height="191"
    />
</div>
<h3>
    Original vs processed
</h3>
<p>
    Where the processed information displayed is different from the data supplied with the record, the original data is also displayed:
</p>
<div class="screenshot">
    <img
            src="${request.contextPath}/static/images/help/screenshot_original_vs_processed.jpg"
            alt="Screen capture Original vs processed window"
            width="522"
            height="201"
    />
</div>
<p>
    You can compare all the processed and original data by clicking on the <span class="feature">Original vs processed</span> button.
</p>


</div>
</body>
</html>
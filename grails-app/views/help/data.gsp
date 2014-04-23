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
    <title>${shortName} - Data</title>
    <r:require modules="help"/>
</head>

<body>
<div id="toc">&nbsp;</div>

<div id="help_content">

<h1 id="${shortName}_data">
    ${shortName} data
</h1>
<p>
    ${fullName} (${shortName}) is the contribution of Australian herbaria to the Atlas of Living Australia (ALA). Currently, data is delivered to ${shortName}
    by the eight Commonwealth, state and territory herbaria and the Australian Tropical Herbarium. We hope to include records from university herbaria in the near future.
</p>
<p>
    Herbarium specimen data is catalogued in accordance with the data entry standards and protocols of each herbarium. The data is then exported to ${shortName} using
    the HISPID (Herbarium Information Systems Protocol for the Interchange of Data) standard. Most contributing herbaria deliver their data to ${shortName}
    dynamically using a <a href="http://www.biocase.org/products/provider_software/">BioCASe provider</a>, which provides new and updated records to ${shortName} on a daily
basis.
</p>
<p>
    Once aggregated in the ALA BioCache, the data is further standardised and a range of quality checks are applied to enhance data retrieval and analysis. The
    standardisation and data processing applied in the BioCache is described below. The unprocessed data provided by the herbaria is always available; an
    overview of the provided versus processed data is available for each record via the <a href="help.html#record_detail"><span class="feature">Record detail</span></a> page.
</p>
<p>
    Australia’s Virtual Herbarium contains records of the holdings of Australian herbaria, both of Australian and foreign
    collections. It also contains records of cultivated plants and introduced occurrences and while there is the
    <i>establishment means</i> field to indicate whether a plant is cultivated or not native, this has not always been
used. AVH records may also just be wrong. A record in AVH of a species from a certain location only means that
there is a specimen with this species name from the given location, not necessarily that the species naturally
occurs at that location. The major asset of AVH is that all records are based on preserved specimens, so they can,
to a large extent, be verified. It is up to the user to decide whether or not verification is necessary. By itself
AVH data is not more authoritative than data you get from anywhere else.
</p>
<h2>
    Specimen
</h2>
<h3>
    Herbarium
</h3>
<p>
    The name of the herbarium at which the specimen is held.
</p>
<h3>
    Herbarium code
</h3>
<p>
    The <a href="http://sweetgum.nybg.org/ih/">Index Herbariorum</a> code of the herbarium at which the specimen is held.
</p>
<h3>
    Catalogue number
</h3>
<p>
    An identifier that identifies the physical specimen. In ${shortName}, catalogue numbers consist of the <span class="feature">Herbarium code</span>, followed by a space and then the catalogue
number used at the institution. The search for catalogue number uses an exact match, so the catalogue number entered needs to be exactly the same as it is
in ${shortName}. Catalogue number formats applied at the different herbaria are listed in Table 1.
</p>
<p>
    <b>Table 1.</b> Catalogue number formats used by the herbaria that contribute data to Australia's Virtual Herbarium
</p>
<div>
    <table>
        <colgroup>
            <col width="270"/>
            <col width="116"/>
            <col width="*"/>
        </colgroup>
        <tbody>
        <tr>
            <th>
                Herbarium
            </th>
            <th>
                Format
            </th>
            <th>
                Description
            </th>
        </tr>
        <tr>
            <td>
                Australian National Herbarium
            </td>
            <td>
                CANB 000000
            </td>
            <td>
                a number of up to six digits
            </td>
        </tr>
        <tr>
            <td>
            </td>
            <td>
                CBG 0000000
            </td>
            <td>
                a number of up to seven digits
            </td>
        </tr>
        <tr>
            <td>
                Australian Tropical Herbarium
            </td>
            <td>
                CNS 000000
            </td>
            <td>
                a number of up to six digits
            </td>
        </tr>
        <tr>
            <td>
            </td>
            <td>
                QRS 000000
            </td>
            <td>
                a number of up to six digits
            </td>
        </tr>
        <tr>
            <td>
                National Herbarium of New South Wales
            </td>
            <td>
                NSW 000000
            </td>
            <td>
                a number of up to six digits
            </td>
        </tr>
        <tr>
            <td>
                National Herbarium of Victoria
            </td>
            <td>
                MEL 0000000X
            </td>
            <td>
                a string of seven digits (with leading zeroes for numbers less than 1000000) followed by one letter
            </td>
        </tr>
        <tr>
            <td>
                Northern Territory Herbarium
            </td>
            <td>
                DNA X0000000
            </td>
            <td>
                a string of one letter followed by seven digits &ndash; the letter indicates whether the specimen originates from the Darwin Herbarium (D) or the
            Alice Springs Herbarium (A)
            </td>
        </tr>
        <tr>
            <td>
                Queensland Herbarium
            </td>
            <td>
                BRI AQ0000000
            </td>
            <td>
                a string of two letters (AQ) followed by seven digits
            </td>
        </tr>
        <tr>
            <td>
                State Herbarium of South Australia
            </td>
            <td>
                AD 00000000
            </td>
            <td>
                a number of up to nine digits, sometimes followed by a single letter
            </td>
        </tr>
        <tr>
            <td>
            </td>
            <td>
                AD-A 00000(X)
            </td>
            <td>
                a number of up to five digits, sometimes followed by a single letter
            </td>
        </tr>
        <tr>
            <td>
            </td>
            <td>
                AD-C 00000(X)
            </td>
            <td>
                a number of up to five digits, sometimes followed by a single letter
            </td>
        </tr>
        <tr>
            <td>
                Tasmanian Herbarium
            </td>
            <td>
                HO 000000
            </td>
            <td>
                a number of up to six digits
            </td>
        </tr>
        <tr>
            <td>
                Western Australian Herbarium
            </td>
            <td>
                PERTH 0000000
            </td>
            <td>
                a number of up to eight digits
            </td>
        </tr>
        </tbody>
    </table>
</div>
<p>
    Note that previous versions of ${shortName} used the term 'Accession number' instead of catalogue number.
</p>
<h3>
    ALA record ID
</h3>
<p>
    The unique identifier applied to the specimen record in the ALA BioCache. The <span class="feature">ALA record ID</span> is listed in the <a href="help.html#downloads"><span class="feature">CSV downloads</span></a> and in the URL of the <a href="help.html#record_detail"><span class="feature">Record detail</span></a> page. You can use the <span class="feature">ALA record ID</span> to find the most up-to-date data for the specimen record by typing '${hostname}/[record
ID]' in the navigation bar of your browser.
</p>
<h3>
    Basis of record
</h3>
<p>
    <span class="feature">Basis of record</span> describes the source of the information in a record. Occurrence records are generally either based on an object (such as a preserved
specimen), or on an observation of an organism in the field. Object-based records are more verifiable than observation-based records, because the specimens
are held in permanent collections and can be examined at a later date and the identification can be verified. All ${shortName} records are based on objects.
</p>
<h3>
    Preparations
</h3>
<p>
    The preparation type of the specimen ('Sheet', 'Packet' etc.).
</p>
<h3>
    Date last updated
</h3>
<p>
    The date the record was last updated. On the <a href="help.html#record_detail"><span class="feature">Record detail</span></a> pages this is shown as <span class="feature">Date loaded</span> and will appear under the location map. The <span class="feature">Date last processed</span> indicates when the record was last processed within the ALA BioCache. This may happen, for instance, when there is a change in the backbone
taxonomy or the Sensitive Data Service, or when new environmental layers are loaded.
</p>
<h2>
    Collecting event
</h2>
<h3>
    Collector
</h3>
<p>
    The name of the collector, as provided with the specimen record.
</p>
<h3>
    Collecting number
</h3>
<p>
    The number (or other identifier) assigned to the specimen by the collector.
</p>
<h3>
    Additional collectors
</h3>
<p>
    The names of any additional collectors who were present at the time the specimen was collected.
</p>
<h3>
    Collecting date
</h3>
<p>
    The date that the specimen was collected. Collecting dates in ${shortName} are delivered in two ways: as <span class="feature">Collecting date</span>, which has to be ISO compliant, or as
    <span class="feature">Verbatim collecting date</span>. Some herbaria deliver <span class="feature">Verbatim collecting date</span> only when an ISO-compliant <span class="feature">Collecting date</span> can't be delivered, or not all information can be delivered as an ISO-compliant date (e.g. 'Summer of '69'), while others deliver it for all collecting dates. Because of database
restrictions, some herbaria are only able to deliver incomplete collecting dates as <span class="feature">Verbatim collecting date</span>. We hope to remedy this in the near future.
</p>
<p>
    Approximately six per cent of ${shortName} specimen records are undated. These will predominantly be historical (pre-1900) records, but will also include records
    collected in the twentieth century.
</p>
<h4>
    Querying by date
</h4>
<p>
    The <span class="feature">Collecting date</span> term in the <a href="help.html#advanced_search"><span class="feature">Advanced search</span></a> form allows you to query for a range of collecting dates. If you enter just a start date or an end date,
your results will include records of specimens collected since or up to that date respectively. To query for a particular collecting date, enter the same
date in both fields. Because of problems associated with querying incomplete dates, the results for a search that includes a collecting date term will only
return records with complete collecting dates.
</p>
<h4>
    Date facets
</h4>
<p>
    There are <span class="feature">Year</span>, <span class="feature">Month</span> and <span class="feature">Decade</span> facets on the <a href="help.html#results"><span class="feature">Results</span></a> page that allow you to filter your results for records collected in a particular year, month or
decade. Note that the <span class="feature">Decade</span> facet and chart only include records with complete collecting dates; records with only a month and a year, or just a year,
will not be counted.
</p>
<h3>
    Locality
</h3>
<p>
    The locality at which the specimen was collected.
</p>
<h3>
    Habitat
</h3>
<p>
    A description of the habitat that the plant, alga or fungus was growing in, provided by the collector(s) of the specimen. Some herbarium databases have
    this information split into multiple fields, e.g. 'Habitat', 'Associated taxa', 'Substrate' and 'Host', but the information from the separate fields is
    concatenated before being delivered to ${shortName}.
</p>
<h3>
    Collecting notes
</h3>
<p>
    Any additional notes about the specimen or the collecting event provided by the collector. Some herbaria store this information in multiple fields in their
    herbarium databases, for example 'Collecting notes' and 'Descriptive notes', but this information is concatenated for delivery to ${shortName}. Some herbarium
    databases have a general notes field and no other place to store notes from determiners or data entry personnel &ndash; and even those that do have dedicated
fields for other types of notes have not always had them &ndash; so, for many records, <span class="feature">Collecting notes</span> will contain more than just collecting notes.
</p>
<h3>
    Phenology
</h3>
<p>
    The <span class="feature">Phenology</span> field indicates whether the specimen is bearing flowers or fruits, etc. Only two herbaria, MEL and NSW, deliver this information.
</p>
<h3>
    Establishment means
</h3>
<p>
    <span class="feature">Establishment means</span> describes how the specimen was established at the collecting locality. It combines the HISPID concepts 'Cultivation status' and
'Natural occurrence'. Cultivation status can be one of the following values: 'Cultivated', 'Not cultivated', 'Assumed to be cultivated' and 'Doubtfully
cultivated'. Cultivation status is not recorded consistently among the different herbaria, and is not provided by all herbaria. Natural occurrence
indicates whether the occurrence is natural or whether the specimen has been introduced at the collecting locality. Allowed values are: 'Native', 'Assumed
to be native', 'Doubtfully native' and 'Not native'. This information is recorded rather haphazardly.
</p>
<h3>
    Conservation status
</h3>
<p>
    The conservation status associated with the taxon in the state or territory in which it was collected. The classification codes for each state or territory
    are listed in Table 2.
</p>
<p>
    <b>Table 2</b>. Conservation status classification codes for Australian states and territories.
</p>
<div>
<table>
<colgroup>
    <col width="234"/>
    <col width="*"/>
</colgroup>
<tbody>
<tr>
    <th>
        State
    </th>
    <th>
        Classification codes
    </th>
</tr>
<tr>
    <td>
        <a href="http://collections.ala.org.au/public/show/dr467">Western Australia</a>
    </td>
    <td>
        <ul>
            <li>
                Presumed Extinct.
            </li>
            <li>
                Critically Endangered.
            </li>
            <li>
                Endangered.
            </li>
            <li>
                Vulnerable.
            </li>
            <li>
                Priority One: Poorly known taxa with few populations on threatened lands.
            </li>
            <li>
                Priority Two: Poorly known taxa with few populations including some on conservation lands.
            </li>
            <li>
                Priority Three: Poorly known taxa with several or widespread populations.
            </li>
            <li>
                Priority Four: Rare but not threatened taxa in need of monitoring.
            </li>
            <li>
                Priority Five: Conservation dependent taxa that are dependent on ongoing active management.
            </li>
        </ul>
    </td>
</tr>
<tr>
    <td>
        <a href="http://collections.ala.org.au/public/show/dr651">Northern Territory</a>
    </td>
    <td>
        <ul>
            <li>
                Extinct in the Wild
            </li>
            <li>
                Critically Endangered
            </li>
            <li>
                Endangered
            </li>
            <li>
                Vulnerable
            </li>
            <li>
                Near threatened
            </li>
            <li>
                Data deficient
            </li>
        </ul>
    </td>
</tr>
<tr>
    <td>
        <a href="http://collections.ala.org.au/public/show/dr653">South Australia</a>
    </td>
    <td>
        <ul>
            <li>
                Endangered or extinct
            </li>
            <li>
                Vulnerable
            </li>
            <li>
                Rare
            </li>
        </ul>
    </td>
</tr>
<tr>
    <td>
        <a href="http://collections.ala.org.au/public/show/dr652">Queensland</a>
    </td>
    <td>
        <ul>
            <li>
                Extinct in the wild
            </li>
            <li>
                Endangered
            </li>
            <li>
                Vulnerable
            </li>
            <li>
                Near threatened
            </li>
            <li>
                Least concern
            </li>
        </ul>
    </td>
</tr>
<tr>
    <td>
        <a href="http://collections.ala.org.au/public/show/dr650">New South Wales</a>
    </td>
    <td>
        <ul>
            <li>
                Presumed Extinct
            </li>
            <li>
                Critically Endangered
            </li>
            <li>
                Endangered
            </li>
            <li>
                Vulnerable
            </li>
            <li>
                Endangered Population
            </li>
        </ul>
    </td>
</tr>
<tr>
    <td>
        <a href="http://collections.ala.org.au/public/show/dr649">Australian Capital Territory</a>
    </td>
    <td>
        <ul>
            <li>
                Endangered
            </li>
            <li>
                Vulnerable
            </li>
        </ul>
    </td>
</tr>
<tr>
    <td>
        <a href="http://collections.ala.org.au/public/show/dr655">Victoria</a>
    </td>
    <td>
        <ul>
            <li>
                Presumed Extinct
            </li>
            <li>
                Endangered
            </li>
            <li>
                Vulnerable
            </li>
            <li>
                Rare
            </li>
            <li>
                Poorly known
            </li>
        </ul>
    </td>
</tr>
<tr>
    <td>
        <a href="http://collections.ala.org.au/public/show/dr654">Tasmania</a>
    </td>
    <td>
        <ul>
            <li>
                Extinct
            </li>
            <li>
                Endangered
            </li>
            <li>
                Vulnerable
            </li>
            <li>
                Rare
            </li>
        </ul>
    </td>
</tr>
</tbody>
</table>
</div>
<h2>
    Taxonomy
</h2>
<h3>
    Taxon names in ${shortName}
</h3>
<p>
    The ALA applies taxon name resolution to incoming data. The taxon name with a record will be stored in the ALA BioCache exactly as it is delivered to ${shortName} &ndash;
    called <span class="feature">Taxon name (provided)</span> in ${shortName} &ndash; but the taxon name will also be processed. The processing of the taxon name includes parsing the name into its parts,
e.g. genus name and epithet(s). If the name can be parsed, the name resolver will try to match the canonical name against the ALA name list. If no match
can be found or the name could not be parsed, it will try to match the genus name; if the genus name is not in the ALA name list, it will try to match the
name of the family, which is provided separately.
</p>
<p>
    If a matched name is in one of the authoritative national checklists that are part of the ALA name list, such as the <a href="http://www.anbg.gov.au/chah/apc/">Australian Plant Census</a> (APC), and if
the matched name is considered a synonym, the processed name will be the accepted name from the checklist. The processed taxon name is called <span class="feature">Taxon name (processed)</span> in ${shortName}.
</p>
<p>
    The <span class="feature">Taxon rank (matched)</span> is the rank of the processed taxon name. This may be the same rank as the rank of the provided name, or a higher rank. If the rank
of the processed name is different from that of the provided name, and the name resolver can work out the rank of the provided name, the rank of the
provided name will be given on the <a href="help.html#record_detail"><span class="feature">Record detail</span></a> page as well.
</p>
<p>
    The <span class="feature">Name match metric</span> describes how the provided name was matched to a name in the ALA name list. If the parsed name was matched, the <span class="feature">Name match metric</span>
    will be 'Canonical name match'. 'Higher taxa match' means that the name itself could not be matched, but the name of a higher taxon &ndash; genus or family &ndash;
    could. 'No match' means that neither the provided name nor the name of a higher taxon could be matched to a name in the ALA name list.
</p>
<p>
    <span class="feature">Author</span> is the authorship of the processed name. The authorship of the provided name is given as part of <span class="feature">Taxon name (provided)</span>.
</p>
<p>
    The <span class="feature">Common name</span> is the common name recorded in the ALA name list. Common names are never provided by the herbaria.
</p>
<h3>
    Classification
</h3>
<p>
    There are facets for taxonomic groups of all mandatory ranks &ndash; <span class="feature">Kingdom</span>, <span class="feature">Phylum</span>, <span class="feature">Class</span>, <span class="feature">Order</span>, <span class="feature">Family</span>, <span class="feature">Genus</span>, <span class="feature">Species</span> &ndash; and for <span class="feature">Infraspecific taxon</span>. These
taxonomic groups are also given on the <a href="help.html#record_detail"><span class="feature">Record detail</span></a> page and in the <a href="help.html#downloads"><span class="feature">CSV downloads</span></a>. If there was no match for a provided name, the names of the taxonomic
groups provided with the specimen record will be displayed.
</p>
<h3>
    Botanical group
</h3>
<p>
    The <span class="feature">Botanical group</span> facet allows you to select records of a botanical group that is not necessarily a taxonomic group, for example, bryophytes, angiosperms
or dicotyledons. Some other useful groupings, e.g. lichens, have not been implemented yet, but will be added when the National Species Lists have been
completed. As these are not taxonomic groups, botanical groups may overlap and not all taxa are represented in one of the recognised groups.
</p>
<h3>
    Determination qualifier
</h3>
<p>
    The <span class="feature">Determination qualifier</span> facet can be used to select records with certain determination qualifiers, or to exclude records with uncertain determination.
Note that excluding records with uncertain determination disqualifies all records with determination qualifiers, no matter at what rank the qualifier
applies. If a qualifier applies at the infraspecific rank you might want to include the determination in the results of a taxon name query. In this case
you are better off keeping the uncertain determinations and deleting the ones that you don't want from the output, or do a filter on uncertain
determinations and see what you are going to throw out.
</p>
<h3>
    Addendum
</h3>
<p>
    The taxon name addendum is a qualifier that comes after the taxon name. Name addenda endorsed by HISPID (translated in proper English) are 's. str.' (in
    the narrow sense), 's.l.' (in the broad sense) and 'agg.' (aggregate, group, complex). The first two are supposed to be used to differentiate between
    competing taxon concepts, but s.l. is often used to indicate uncertainty about whether the specimen belongs to the taxon in question, or if it belongs to a
    similar taxon. In this case, 'agg.' would have been more appropriate to use. Often aggregates are not formally recognised, although there is mostly general
    agreement on what the complexes are. For general use it is probably best to ignore 's. str.' and treat determinations with the other name addenda as
    uncertain determinations.
</p>
<h3>
    Determiner
</h3>
<p>
    The person or persons who last determined the specimen. Due to the practice at some Australian herbaria of changing the name on specimens as part of the
    curatorial process, without examining the specimen, a lot of this information is meaningless or even misleading.
</p>
<h3>
    Determiner role
</h3>
<p>
    The role the determiner has played in the determination, e.g. determined the specimen ('Det.') or confirmed an earlier determination ('Conf.').
</p>
<h3>
    Determination date
</h3>
<p>
    The <span class="feature">Determination date</span> term in the <a href="help.html#advanced_search"><span class="feature">Advanced search</span></a> allows you to query for a range of determination dates. If you fill in just a start date or an end date, your results
will include records of specimens determined since or up to that date respectively. In order to query for a particular determination date, enter the same
date in both fields. Because of problems associated with querying incomplete dates, a result for a search that includes a determination date term will only
include records with complete determination dates. It is common practice to give only a month and year on determination slips, so be aware that a large
part of the determinations will be missed when querying by determination date.
</p>
<h3>
    Determination notes
</h3>
<p>
    <span class="feature">Determination notes</span> are any notes that are made by the determiner at the time of the determination. These may include diagnostic features, a reference to
the work that was used to identify the specimen, or an indication that the specimen is not typical for the taxon. Due to the structure of some herbarium
databases, determination notes have often been included in <span class="feature">Collecting notes</span>.
</p>
<h3>
    Type status
</h3>
<p>
    The type status of any type specimens in the results. Note that, if you searched by a taxon name, a type specimen in the result is not necessarily a type
    of the name that you searched for.
</p>
<h2>
    Geography
</h2>
<p>
    The values in many of the following geography fields have been inferred from the latitude and longitude provided with the specimen records. In some cases,
    the geography values stored in the herbarium record may differ from the inferred values due to geocoding errors. If you suspect that there is an error with
    a record, you can flag an issue on the <a href="help.html#record_detail"><span class="feature">Record detail</span></a> page.
</p>
<h3>
    Country
</h3>
<p>
    The country in which the specimen was collected. Note that, while most Australian herbaria hold specimens collected outside Australia, only a small
    proportion of foreign holdings have been databased and made available through ${shortName}.
</p>
<h3>
    State or territory
</h3>
<p>
    The state or territory that Australian specimens were collected in. Queries for records from countries other than Australia cannot be limited to political
    divisions below the country level.
</p>
<h3>
    Local government area
</h3>
<p>
    The local government area in which the specimen was collected, based on the latitude and longitude provided with the specimen record.
</p>
<h3>
    Latitude and longitude
</h3>
<p>
    The latitude and longitude of the collecting locality. If correctable errors are detected, for example the latitude or longitude is in the wrong hemisphere
    or the latitude and longitude are transposed, the values are corrected and the unprocessed latitude and longitude are given in the <span class="feature">Latitude (provided)</span> and
    <span class="feature">Longitude (provided)</span> fields in the <a href="help.html#record_detail"><span class="feature">Record detail</span></a> page and in downloaded results.
</p>
<h3>
    Geodetic datum
</h3>
<p>
    The geodetic datum is the reference from which the latitude and longitude are measured. The most common datums are WGS84, GDA94 and AGD66. While important
    for records of more recent collections, the inaccuracy of the georeferences in the bulk of the ${shortName} records is much greater than the differences between the
    different datums. <span class="feature">Geodetic datum</span> is very haphazardly delivered with ${shortName} data, even with georeferences that are accurate enough for the geodetic datum to be
meaningful.
</p>
<h3>
    Geocode uncertainty
</h3>
<p>
    The <span class="feature">Geocode uncertainty</span> is a measurement or estimate of how far away in metres the point represented by the latitude and longitude may be from the actual
location where the specimen was collected. Most herbaria use ranges in their collections databases, for example 0-100 m, 100 m-1 km, 1-10 km, 10-25 km and
&gt;25 km. The values that are delivered to ${shortName} are the maximum values of these ranges.
</p>
<h3>
    Georeferencing method
</h3>
<p>
    The method by which the georeference was obtained, for example by GPS or by using a topographic map. In the HISPID standard, which is used for data
    delivery to ${shortName}, 'Geocode source' is a mixed concept and includes both generalisations for the method used and for the person who provided the
    georeference. In ${shortName}, the terms that refer to the person who provided the georeference are stored under <span class="feature">Georeferenced by</span>.
</p>
<h3>
    Georeferenced by
</h3>
<p>
    A general term for the person who provided the georeference ('Collector' or 'Compiler').
</p>
<h3>
    Altitude
</h3>
<p>
    The altitude in metres of the collecting locality, if provided with the specimen record. Altitude is presented in ${shortName} as <span class="feature">Minimum altitude (m)</span> and <span class="feature">Maximum altitude (m)</span>. If a single value for altitude is provided, which will mostly be the case, this will be given as <span class="feature">Minimum altitude (m)</span>. If a range is provided a
    <span class="feature">Maximum altitude (m)</span> will also be given.
</p>
<h3>
    Depth
</h3>
<p>
    The depth in metres where the specimen was collected. Depth is presented in ${shortName} as <span class="feature">Minimum depth (m)</span> and <span class="feature">Maximum depth (m)</span>. If a single value for depth is provided, which will mostly be the case, this will be given as <span class="feature">Minimum depth (m)</span>. If a range is provided a <span class="feature">Maximum depth (m)</span> will also be given.
</p>
<h3>
    IBRA region
</h3>
<p>
    The <a href="http://spatial.ala.org.au/layers/more/ibra_merged">Interim Biogeographic Regionalisation for Australia (IBRA) region</a> that corresponds to the latitude and longitude provided with the specimen record.
</p>
<h3>
    IMCRA region
</h3>
<p>
    The <a href="http://spatial.ala.org.au/layers/more/imcra_meso">Integrated Marine and Coastal Regionalisation of Australia (IMCRA) meso-scale
bioregion</a> that corresponds to the latitude and longitude provided with the specimen record.
</p>
<h3>
    Biogeographic region
</h3>
<p>
    The combined IBRA and IMCRA biogeographic regions. This facet is hidden by default, but can be selected under the <a href="help.html#refine_results"><span class="feature">Refine results</span></a> options.
</p>
<h3>
    Ecoregion
</h3>
<p>
    The ecoregion (non-marine, marine, or limnetic) in which the taxon occurs. The data comes from the <a href="http://www.obis.org.au/irmng/">Interim Register of Marine and Nonmarine Genera (IRMNG)</a> and is based on the genus name, not from the latitude and longitude associated with the record. Not all genus names in ${shortName} are in IRMNG.
</p>
<h3>
    Vegetation type
</h3>
<p>
    The Major Vegetation Groups (from the <a href="http://www.environment.gov.au/erin/nvis/mvg/">National Vegetation Information System</a>)
at the collecting locality, inferred from the latitude and longitude provided with the specimen record. There are layers and facets for both the extant
vegetation type (<span class="feature">Vegetation types: extant</span>) and the estimated vegetation before European settlement(<span class="feature">Vegetation types: pre-1750</span>).
</p>
<h2>
    Herbarium transactions
</h2>
<h3>
    Duplicates sent to
</h3>
<p>
    The herbaria to which duplicates have been sent. Herbaria are identified by their <a href="http://sweetgum.nybg.org/ih/"> Index Herbariorum</a>
    acronym. When querying this field, note that the specimen records in the results will be from the herbarium that sent the duplicates, not the herbaria that
    received the duplicates. A potential use case of the <span class="feature">Duplicates sent to</span> query term in the <a href="help.html#advanced_search"><span class="feature">Advanced search</span></a> would be a herbarium trying to find the original records of specimens they have received on exchange from all other Australian herbaria, or, if used in combination with the <span class="feature">Herbarium field</span>, from one particular Australian herbarium.
</p>
<h3>
    Herbarium received from
</h3>
<p>
    The herbarium from which the specimen was received. In most cases, but not all, this will be the herbarium where the original specimen is held. Herbaria
    are identified by their <a href="http://sweetgum.nybg.org/ih/"> Index Herbariorum</a> acronym.
</p>
<h3>
    Ex herb. catalogue number
</h3>
<p>
    The catalogue number for the original specimen at the herbarium from which a duplicate specimen was received.
</p>
<h3>
    Loan number
</h3>
<p>
    The <span class="feature">Loan number</span> is the reference number or identifier assigned to the loan by the lending institution, and is used by the lender and the borrower for
administrative purposes. Searching by loan number enables botanists who have borrowed from a herbarium that delivers loan data to ${shortName} (currently only AD
and MEL) to retrieve the records for all specimens in a particular loan.
</p>
<h3>
    Borrowing institution
</h3>
<p>
    The <a href="http://sweetgum.nybg.org/ih/"> Index Herbariorum</a> acronym of the borrowing institution.
</p>
<h2>
    Data quality checks
</h2>
<h3>
    Data issues
</h3>
<p>
    When ${shortName} data is uploaded into the BioCache, a range of quality assurance checks are performed and potential data issues are flagged. Some data issues
    (such as transposed or negated latitude and longitude) will result in the data being modified; other issues will simply be flagged. The details of any
    changes made during processing can be viewed by clicking on the <a href="help.html#original_vs_processed"><span class="feature">Original vs Processed</span></a> button on the <a href="help.html#record_detail"><span class="feature">Record detail</span></a> page. Users can also flag potential issues with specimen records by using the <a href="help.html#flag_an_issue"><span class="feature">Flag an issue</span></a> feature on the <a href="help.html#record_detail"><span class="feature">Record detail</span></a> page. Data issues detected during processing or flagged by users are available as a facet on the <a href="help.html#results"><span class="feature">Results</span></a> page, and can be used to narrow down your search results. The range of data issues in ${shortName} are described in Table 3. The data issues are also available on the <a href="help.html#record_detail"><span class="feature">Record detail</span></a> page and in the <a href="help.html#downloads"><span class="feature">CSV downloads</span></a>.
</p>
<p>
    <b>Table 3.</b> Types of data issues identified in Australia's Virtual Herbarium.
</p>
<div>
<table>
<colgroup>
    <col width="200"/>
    <col width="*"/>
</colgroup>
<tbody>
<tr>
    <th>
        Issue
    </th>
    <th>
        Description
    </th>
</tr>
<tr>
    <td colspan="2">
        <b>Dataset</b>
    </td>
</tr>
<tr>
    <td>
        Basis of record badly formed
    </td>
    <td>
        The value provided in the <span class="feature">Basis of record</span> field could not be mapped against the standard vocabulary used by ALA.
    </td>
</tr>
<tr>
    <td>
        Collection date missing
    </td>
    <td>
        The collecting date is unknown, or was not provided with the specimen record.
    </td>
</tr>
<tr>
    <td>
        Invalid collection date
    </td>
    <td>
        The collecting date was given as pre-1700, or was otherwise invalid. The National Herbarium of Victoria (MEL) holds several specimens that
        were collected earlier than 1700, so not all pre-1700 collecting dates will be errors.
    </td>
</tr>
<tr>
    <td>
        Type status not recognised
        <br/>
    </td>
    <td>
        The type status provided with the record could not be mapped against the standard vocabulary used by ALA.
    </td>
</tr>
<tr>
    <td colspan="2">
        <b>Taxonomy</b>
    </td>
</tr>
<tr>
    <td>
        Homonym issues with supplied name
    </td>
    <td>
        The <span class="feature">Taxon name (provided)</span> is a homonym, and so can't be processed.
    </td>
</tr>
<tr>
    <td>
        Name not in national checklists
    </td>
    <td>
        The <span class="feature">Taxon name (provided)</span> is not in the national species lists for the country in which it was collected, but it is in other checklists,
    for example, the <a href="http://www.catalogueoflife.org/">Catalogue of Life</a>.
    </td>
</tr>
<tr>
    <td>
        Name not recognised
    </td>
    <td>
        The <span class="feature">Taxon name (provided)</span> cannot be located on any national or international species checklists.
    </td>
</tr>
<tr>
    <td>
        Taxon misidentified
    </td>
    <td>
        A user has flagged the record as possibly being misidentified.
    </td>
</tr>
<tr>
    <td colspan="2">
        <b>Geospatial</b>
    </td>
</tr>
<tr>
    <td>
        Coordinate uncertainty not specified
    </td>
    <td>
        The <span class="feature">Coordinate uncertainty</span> was not provided with the specimen record.
    </td>
</tr>
<tr>
    <td>
        Coordinate uncertainty not valid
    </td>
    <td>
        The <span class="feature">Coordinate uncertainty</span> value is less than 1.
    </td>
</tr>
<tr>
    <td>
        Coordinates are out of range
    </td>
    <td>
        The latitude or longitude provided is greater than 180° or less than -180°.
    </td>
</tr>
<tr>
    <td>
        Coordinates are transposed
    </td>
    <td>
        The latitude and longitude values delivered with the record appear to have been transposed.
    </td>
</tr>
<tr>
    <td>
        Coordinates centre of country
    </td>
    <td>
        The latitude and longitude provided with the record correspond to the centre of the country in which the specimen was collected.
        <br/>
        Not all records flagged with this issue will be in error; check the <span class="feature">Geocode uncertainty</span> and <span class="feature">Locality</span> fields to see if the record is
    genuinely from the centre of the country.
    </td>
</tr>
<tr>
    <td>
        Coordinates don't match supplied state
    </td>
    <td>
        The latitude and longitude provided with the record do not fall within the state or territory provided with the specimen record.
    </td>
</tr>
<tr>
    <td>
        Geospatial issue
    </td>
    <td>
        A user has flagged the record as having a geospatial issue.
    </td>
</tr>
<tr>
    <td>
        Habitat incorrect for species
    </td>
    <td>
        A user has flagged the habitat information as being incorrect for the taxon to which the specimen has been identified.
    </td>
</tr>
<tr>
    <td>
        Latitude is negated
    </td>
    <td>
        The latitude provided appears to be referencing a location in the wrong hemisphere.
    </td>
</tr>
<tr>
    <td>
        Longitude is negated
    </td>
    <td>
        The longitude provided appears to be referencing a location in the wrong hemisphere.
    </td>
</tr>
<tr>
    <td>
        Missing coordinate precision
    </td>
    <td>
        No measure of the precision of the latitude and longitude was provided with the specimen record. Note that coordinate precision is not
        supplied for any ${shortName} records.
    </td>
</tr>
<tr>
    <td>
        Supplied coordinates are zero
    </td>
    <td>
        The latitude and longitude provided with the specimen are 0, instead of being null. It is unlikely that any specimens in ${shortName} were actually
        collected at 0° latitude and 0° longitude.
    </td>
</tr>
<tr>
    <td>
        Supplied coordinates centre of state
    </td>
    <td>
        The latitude and longitude provided with the record correspond to the centre of the state or territory in which the specimen was collected.
        <br/>
        Not all records flagged with this issue will be in error; check the <span class="feature">Geocode uncertainty</span> and <span class="feature">Locality</span> fields to see if the record is
    genuinely from the centre of the state or territory.
    </td>
</tr>
<tr>
    <td>
        Supplied country not recognised
    </td>
    <td>
        The country name provided with the record could not be matched against a standard list of country names.
    </td>
</tr>
<tr>
    <td>
        Suspected outlier
    </td>
    <td>
        A user has flagged the record as being a suspected outlier.
    </td>
</tr>
</tbody>
</table>
</div>
<h3>
    Spatial validity
</h3>
<p>
    An assessment of whether or not the location is spatially valid, based on a range of data quality checks and user-contributed annotations. If the record suffers from one or more of the geospatial <span class="feature">Data issues</span> listed in Table 2 it is considered 'Spatially suspect', otherwise it is 'Spatially valid'. Note that a 'Spatially valid' record is not necessarily correctly georeferenced, and, depending on
the data issue, a 'Spatially suspect' record is not necessarily incorrectly georeferenced.
</p>
<h3>
    Outliers
</h3>
<p>
    Outliers are observations that are distant from the rest of the data in a sample. In ${shortName} the sample is observations of a taxon. The presence of outliers
    might indicate that specimens (the outliers) have been incorrectly identified or georeferenced, but also that the distribution is skewed or disjunct, or
    that the taxon has been under-collected in certain areas. Checks for outliers in ${shortName} are done using five climate surfaces: precipitation seasonality,
    precipitation of the driest quarter, radiation seasonality, radiation of the warmest quarter and mean moisture index of the quarter with the highest
    moisture index. The tests are conducted only where there are 20 or more unique locations for a taxon. For more information on how the tests are done, see
    the notes on the <a href="http://code.google.com/p/ala-dataquality/wiki/DETECTED_OUTLIER_JACKKNIFE">spatial outlier detection method</a> used by ALA.
</p>
<p>
    The <span class="feature">Outlier for layer</span> facet indicates if a specimen is an outlier for an environmental layer, based on the known environmental range of the taxon to which
the specimen has been identified. The <span class="feature">Outlier layer count</span> facet allows you to filter your results for records that are outliers for certain numbers of
environmental layers. You can also display your results by <span class="feature">Outlier for layer</span> or <span class="feature">Outlier layer count</span> on the distribution map. If a record is an outlier for one or
more layers, the <a href="help.html#record_detail"><span class="feature">Record detail</span></a> page will display graphs for each of the variables for which the record is an outlier with the distribution of the records
of the taxon to which it belongs. The layers for which a record is an outlier will also be given in the <a href="help.html#downloads"><span class="feature">CSV downloads</span></a>.
</p>
<h2>
    Sensitive data
</h2>
<p>
    Australia's Virtual Herbarium contains data that may be considered sensitive because of conservation or biosecurity issues. The
    <a href="http://www.ala.org.au/faq/data-sensitivity/">ALA Sensitive Data Service</a>
    contains authoritative lists of taxa that are considered sensitive, obtained in collaboration with Commonwealth, state and territory agencies and data
    providers, with information on how data of these taxa should be handled for each state. Distribution data for these sensitive taxa may be either withheld
    or generalised. The latter means that instead of a detailed locality the local government area will be given and that the latitude and longitude will be
    rounded to, for example, a single decimal place. Currently, distribution data is only completely withheld for a single native species, the Wollemi Pine
    (<i>Wollemia nobilis</i>). There is a <span class="feature">Sensitive data</span> facet that can be used to check for sensitive data among query results. The <a href="help.html#record_detail"><span class="feature">Record detail</span></a> page and the <a href="help.html#downloads"><span class="feature">CSV downloads</span></a> indicate whether distribution data has been withheld or generalised for each record.
</p>
<h2>
    Multimedia
</h2>
<p>
    The <span class="feature">Multimedia</span> facet allows you to filter your results for records that have images or other multimedia attached. Currently, there are no records with
multimedia in ${shortName}, but we aim to get some in in the very near future.
</p>
</div>
</body>
</html>
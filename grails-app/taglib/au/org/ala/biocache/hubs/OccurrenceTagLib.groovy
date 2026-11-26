/*
 * Copyright (C) 2014 Atlas of Living Australia
 * All Rights Reserved.
 *
 * The contents of this file are subject to the Mozilla Public
 * License Version 1.1 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of
 * the License at http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS
 * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * rights and limitations under the License.
 */

package au.org.ala.biocache.hubs

import au.org.ala.dataquality.model.QualityCategory
import grails.web.servlet.mvc.GrailsParameterMap
import groovy.xml.MarkupBuilder
import org.apache.commons.lang.StringEscapeUtils
import org.apache.commons.lang.StringUtils
import org.owasp.html.HtmlPolicyBuilder
import org.owasp.html.PolicyFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.web.servlet.support.RequestContextUtils
import grails.util.Environment

import java.util.regex.Pattern

import static au.org.ala.biocache.hubs.TimingUtils.time

/**
 * Custom taglib for biocache-hubs
 *
 */
class OccurrenceTagLib {
    // injected beans
    def authService
    def webServicesService
    def messageSourceCacheService
    def userService
    def qualityService

    //static defaultEncodeAs = 'html'
    //static encodeAsForTags = [tagName: 'raw']
    static returnObjectForTags = ['getLoggerReasons','message','createFilterItemLink','createInverseQualityCategoryLink']
    static namespace = 'alatag'     // namespace for headers and footers
    static rangePattern = ~/\[\d+(\.\d+)? TO \d+(\.\d+)?\]/

    def maxDynamicProperties = 8
    def maxDynamicPropertyLength = 25

    /**
     * Formats the display of dynamic facet names in Sandbox (facet options popup)
     *
     * @attr fieldName REQUIRED the field name
     */
    def formatDynamicFacetName = { attrs ->
        out << formatFieldName(attrs.fieldName, attrs.fieldName)
    }

    /**
     * Format a dynamic field name.
     *
     * @param fieldName
     * @return
     */
    def formatFieldName(fieldCode, fieldName){
        def output
        if (fieldName.endsWith('_s') || fieldName.endsWith('_i') || fieldName.endsWith('_d')) {
            def temp = fieldName[0..-2].replaceAll("_", " ")
            output = "${alatag.message(code:"facet.${fieldName}", default: temp)}"
        } else if (fieldName.endsWith('_RNG')) {
            output = fieldName[0..-4].replaceAll("_", " ") + " (range)"
        } else {

            def label = message(code:"facet." + fieldCode, default:"")
            if (!label){
                // try without "facet."
                label = message(code:fieldCode, default:"")
            }

            label = label ?: fieldName
            output = label
        }
        output
    }

    def renderTree = { attrs ->
        renderNode(attrs.hierarchy, out)
    }

    def renderNode(hierarchy, out){
        def nodeLabel = hierarchy[0]
        def nodeClass = hierarchy.size() == 1 ? 'selected' :' '
        out << """<ul class='tree'>
                    <li><span class="${nodeClass}">${nodeLabel}</span>
               """
        if (hierarchy.size() > 1) {
            renderNode(hierarchy.subList(1, hierarchy.size()), out)
        }
        out << "</li></ul>"
    }

    /**
     * Format scientific name for HTML display
     *
     * @attr rankId REQUIRED
     * @attr name REQUIRED
     * @attr acceptedName
     */
    def formatSciName = { attrs ->
        def name = attrs.name
        def acceptedName = attrs.acceptedName
        def rankId = attrs.rankId?.toInteger()
        def acceptedNameOutput = ""
        def ital = ["",""]

        if (!rankId || rankId >= 6000) {
            ital = ["<i>","</i>"]
        }

        if (acceptedName) {
            acceptedNameOutput = " (${alatag.message(code:"alatag.accepted.name")}: ${ital[0]}${acceptedName}${ital[1]})"
        }
        def nameOutput = "${ital[0]}${name}${ital[1]}${acceptedNameOutput}"

        out << nameOutput.trim()
    }

    /**
     * Output the appropriate raw scientific name for the record
     *
     * @attr occurrence REQUIRED the occurrence record (jsonObject)
     */
    def rawScientificName = { attrs ->
        def rec = attrs.occurrence
        def name

        if (rec.raw_scientificName) {
            name = rec.raw_scientificName
        } else if (rec.species) {
            name = rec.species
        } else if (rec.genus) {
            name = rec.genus
        } else if (rec.family) {
            name = rec.family
        } else if (rec.order) {
            name = rec.order
        } else if (rec.phylum) {
            name = rec.phylum
        }  else if (rec.kingdom) {
            name = rec.kingdom
        } else {
            name = g.message(code:"record.noNameSupplied", default: "No name supplied")
        }

        out << name
    }

    def paramsHasFilterItem(fq) {
        def fqList = params.list('fq')
        def idx = fqList.findIndexOf { it == fq}
        return idx >= 0
    }

    /**
     * Generate HTML for current filters
     *
     * @attr item the activeFacetMap map entry, required if no key and value provided
     * @attr key String the filter key
     * @attr value Map<String,String> the filter result json object
     * @attr facetValue String the value the corresponds to the existing fq, defaults to $key:${value.value}
     * @attr addCheckBox Boolean
     * @attr cssClass String
     * @attr addCloseBtn Boolean
     */
    def currentFilterItem = { attrs ->
        def item = attrs.item
        def key = attrs.key ?: item.key
        def value = attrs.value ?: item.value
        // activeFacetMap regenerates the original fq with key + ':' + value.value
        // activeFacetObj the original fq is in value.value
        // the caller can elect to provide facetValue or have it default to the activeFacetMap value
        def facetValue = attrs.facetValue ?: key + ':' + value.value
        def filterLabel = value.displayName.replaceFirst(/^\-/, "") // remove leading "-" for exclude searches
        def preFix = (value.displayName.startsWith('-')) ? "<span class='excludeFq'>[exclude]</span> " : ""
        def fqLabel = preFix + filterLabel
        String facetKey = key.replaceFirst("\\(","") // remove brace
        String i18nLabel = alatag.message(code: "facet.${facetKey}", default: "") // i18n lookup

        if (i18nLabel) {
            // replace with i18n values, if found
            fqLabel = fqLabel.replaceAll(facetKey, i18nLabel)
        }

        String hrefValue
        String title
        String fqHiddenInQidClass
        if (paramsHasFilterItem(facetValue)) {
            hrefValue = currentFilterItemLink(attrs, facetValue)
            title = (attrs.title != null ? "${attrs.title}<br><br>" : "") + alatag.message(code:"title.filter.remove", default:"Click to remove this filter")
        } else {
            attrs.addCheckBox = false
            attrs.addCloseBtn = false
            fqHiddenInQidClass = "disabled"
        }
        String color = attrs.cssColor != null ? "color:${attrs.cssColor}" : ""

        def mb = new MarkupBuilder(out)
        mb.a(   href: hrefValue,
                class: "${attrs.cssClass} tooltips activeFilter ${fqHiddenInQidClass}",
                style: color,
                title: title
            ) {
            if (attrs.addCloseBtn) {
                span(class:'closeX pull-right') {
                    mkp.yieldUnescaped("&times;")
                }
            }
            if (attrs.addCheckBox) {
                span(class:'fa fa-check-square-o') {
                    mkp.yieldUnescaped("&nbsp;")
                }
            }
            if (key.contains("occurrence_year")) {
                fqLabel = fqLabel.replaceAll(':',': ').replaceAll('occurrence_year', alatag.message(code: 'facet.occurrence_year', default:'occurrence_year'))
                mkp.yieldUnescaped( fqLabel.replaceAll(/(\d{4})\-.*?Z/) { all, year ->
                    def year10 = year?.toInteger() + 10
                    "${year} - ${year10}"
                })
            } else {
                mkp.yieldUnescaped(alatag.message(code: fqLabel, default: fqLabel).replaceFirst(':',': '))
            }
        }
    }

    def download = { attrs, body ->
        def sr = attrs.remove('searchResults')
        SearchRequestParams searchRequestParams = attrs.remove('searchRequestParams')

        attrs.controller = 'download'
        attrs.params = [
                searchParams: sr?.urlParameters,
                targetUri: request.forwardURI,
                totalRecords: sr?.totalRecords ?: 0
        ]

        out << g.link(attrs, body)
    }

    def createFilterItemLink = { attrs ->
        return currentFilterItemLink(attrs, attrs.facet)
    }

    private String currentFilterItemLink(Map attrs, String facet) {
        def fqList = params.list('fq')

        List<String> newFqList
        if (facet == "all") {
            newFqList = []
        } else {
            def idx = fqList.findIndexOf { it == facet }
            // Some facets are hidden in qids and cannot be removed.
            if (idx >= 0) {
                newFqList = new ArrayList<>(fqList)
                newFqList.remove(idx)
            }
        }

        GrailsParameterMap newParams = params.clone()
        if (newFqList) {
            newParams.fq = newFqList
        } else {
            newParams.remove('fq')
        }

        newParams.remove('startIndex')
        newParams.remove('offset')
        newParams.remove('max')

        attrs.params = newParams
        if (!attrs.action) {
            attrs.action = actionName
        }

        createLink(attrs)
    }

    /**
     *  Generate facet links in the left hand column
     *
     *  @attr facetResult REQUIRED
     *  @attr queryParam REQUIRED
     *  @attr fieldDisplayName
     */
    def facetLinkList = { attrs ->
        def facetResult = attrs.facetResult
        def queryParam = attrs.queryParam
        def mb = new MarkupBuilder(out)
        def linkTitle = "${alatag.message(code:"alatag.filter.results.by")} ${attrs.fieldDisplayName ? attrs.fieldDisplayName.uncapitalize(): facetResult.fieldName}"

        def addCounts = { count ->
            mb.span(class:"facetCount") {
                mkp.yieldUnescaped(" (")
                mkp.yield(g.formatNumber(number: "${count}", format:"#,###,###"))
                mkp.yieldUnescaped(")")
            }
        }

        def lastEl = facetResult.fieldResult.last()

        if (lastEl.label == 'before') {
            // range facets have the "before" special fq element at end - move it to the front of array
            facetResult.fieldResult.pop()
            facetResult.fieldResult.putAt(0, lastEl)
        }

        mb.ul(class:'facets nano-content') {
            facetResult.fieldResult.each { fieldResult ->

                if (fieldResult.count > 0) {
                    // Catch specific facets fields
                    if (fieldResult.fq) {
                        // biocache-service has provided a fq field in the fieldResults list
                        li {
                            a(href: "?${queryParam}&fq=${fieldResult.fq?.encodeAsURL()}",
                                    class: "tooltips",
                                    title: linkTitle
                            ) {
                                span(class: "fa fa-square-o") {
                                    mkp.yieldUnescaped("&nbsp;")
                                }
                                span(class: "facet-item") {
                                    // If we have a translation, we use it, if not we try to use the label translation
                                    // and if not, directly use the label. If the label is missing, use "unknown"
                                    // In search.js this is done a bit differently:
                                    // https://github.com/AtlasOfLivingAustralia/biocache-hubs/blob/00f263640edd802d10a071f5d09d146eaa24af34/grails-app/assets/javascripts/search.js#L1946
                                    if (fieldResult.i18nCode && alatag.message(code: fieldResult.i18nCode) != fieldResult.i18nCode ) {
                                        mkp.yield(alatag.message(code: fieldResult.i18nCode, default: fieldResult.label))
                                    } else {
                                        mkp.yield(alatag.message(code: fieldResult.label ?: 'unknown', default: fieldResult.label))
                                    }
                                    addCounts(fieldResult.count)
                                }

                            }

                        }
                    } else if (facetResult.fieldName.startsWith("occurrence_") && facetResult.fieldResult && facetResult.fieldResult.size() > 1) {
                        // decade date range a special case
                        def decade = processDecadeLabel(facetResult.fieldName, facetResult.fieldResult?.get(1)?.label, fieldResult.label)

                        li {
                            a(href: "?${queryParam}&fq=${decade.fq}",
                                    class: "tooltips",
                                    title: linkTitle
                            ) {
                                span(class: "fa fa-square-o") {
                                    mkp.yieldUnescaped("&nbsp;")
                                }
                                span(class: "facet-item") {
                                    mkp.yieldUnescaped("${decade.label}")
                                    addCounts(fieldResult.count)
                                }
                            }

                        }
                    } else {
                        def label = alatag.message(code: facetResult.fieldName + "." + fieldResult.label, default: '') ?: alatag.message(code: fieldResult.label)
                        def href = "?${queryParam}&fq=${facetResult.fieldName}:"
                        if (isRangeFilter(fieldResult.label)) {
                            href = href + "${fieldResult.label?.encodeAsURL()}"
                        } else {
                            href = href + "%22${fieldResult.label?.encodeAsURL()}%22"
                        }
                        li {
                            a(href: href,
                                    class: "tooltips",
                                    title: linkTitle
                            ) {
                                span(class: "fa fa-square-o") {
                                    mkp.yieldUnescaped("&nbsp;")
                                }
                                span(class: "facet-item") {
                                    mkp.yield(label)
                                    addCounts(fieldResult.count)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private Boolean isRangeFilter(fqValue){
        rangePattern.matcher(fqValue).matches()
    }

    /**
     * Process decade labels
     *
     * @param fieldName
     * @param firstLabel
     * @param fqLabel
     * @return
     */
    private Map processDecadeLabel(String fieldName, String firstLabel, String fqLabel) {
        Map output = [:]

        if (fqLabel.toLowerCase() == "before") {
            output.startDate = "*"
            output.startYear = "${alatag.message(code:"alatag.before")} "
            output.endDate = firstLabel
            output.endYear = output.endDate?.substring(0, 4)
        } else if(fqLabel && fqLabel.length() >= 4) {
            output.startDate = fqLabel
            output.startYear = fqLabel.substring(0, 4)
            output.endDate = fqLabel.replace('0-01-01T00:00:00Z','9-12-31T11:59:59Z')
            output.endYear = " - " + output.endDate.substring(0, 4)
        }
        output.fq = "${fieldName}:[${output.startDate} TO ${output.endDate}]"
        output.label = "${output.startYear} ${output.endYear}"

        output
    }

    /**
     * Determine the recordId TODO
     *
     * @attr record REQUIRED the record object (JsonObject)
     * @attr skin
     */
    def getRecordId = { attrs ->
        def record = attrs.record?:null
        def skin = attrs.skin?:"ala"
        def recordId = record.raw.uuid

        if (skin == 'avh') {
            recordId = record.raw.occurrence.catalogNumber
        } else if (record.raw.occurrence.collectionCode && record.raw.occurrence.catalogNumber) {
            recordId = record.raw.occurrence.collectionCode + ":" + record.raw.occurrence.catalogNumber
        } else if (record.processed.attribution.dataResourceName && record.raw.occurrence.catalogNumber) {
            recordId = record.processed.attribution.dataResourceName + " - " + record.raw.occurrence.catalogNumber
        } else if (record.raw.occurrence.occurrenceID) {
            recordId = record.raw.occurrence.occurrenceID
        }

        out << recordId
    }

    /**
     * Determine the scientific name
     *
     * @attr record REQUIRED the record object (JsonObject)
     */
    def getScientificName = { attrs ->
        def record = attrs.record
        def sciName = ""

        if (record.processed.classification.scientificName) {
            sciName = record.processed.classification.scientificName
        } else if (record.raw.classification.scientificName) {
            sciName = record.raw.classification.scientificName
        } else {
            sciName = "${record.raw.classification.genus} ${record.raw.classification.specificEpithet}"
        }
        out << sciName
    }

    /**
     * Print a <li> for user assertions on occurrence record page
     *
     * @attr groupedAssertions REQUIRED
     */
    def groupedAssertions = { attrs ->
        List groupedAssertions = attrs.groupedAssertions
        def mb = new MarkupBuilder(out)

        groupedAssertions.each { assertion ->

            mb.li(id: assertion?.usersAssertionUuid) {
                mkp.yield(alatag.message(code: "${assertion.name}", default :"${assertion.name}"))

                if (assertion.assertionByUser) {
                    br()
                    strong() {
                        mkp.yield(" (added by you")
                        if (assertion.users?.size() > 1) {
                            mkp.yield(" and ${assertion.users.size() - 1} other user${(assertion.users.size() > 2) ? 's':''})")
                        } else {
                            mkp.yield(")")
                        }
                    }
                } else {
                    mkp.yield(" (added by ${assertion.users?.size()} user${(assertion.users?.size() > 1) ? 's':''})")
                }
            }
        }
    }

    /**
     * Generate the icon and popup for the data quality help codes/links
     *
     * @attr code REQUIRED
     */
    def dataQualityHelp = { attrs ->
        def mb = new MarkupBuilder(out)
        mb.a(
                href: "#",
                class:"dataQualityHelpLink",
                "data-toggle":"popover",
                "data-code": attrs.code?:""
        ) {
            i(class:"glyphicon glyphicon-question-sign", "")
        }
        //def html = "&nbsp;<a href='#' class='dataQualityHelpLink' data-toggle='popover' data-code='${code}'><i class='icon-question-sign'></i></a>"
        //out << html
    }

    /**
     * Generate the table body for the raw vs processed table (popup)
     *
     * @attr map REQUIRED
     */
    def formatRawVsProcessed = { attrs ->
        def map = attrs.map
        def mb = new MarkupBuilder(out)

        map.each { group ->
            if (group.value) {
                group.value.eachWithIndex() { field, i ->
                    mb.tr() {
                        if (i == 0) {
                            td(class:"noStripe", rowspan:"${group.value.length()}") {
                                b(g.message(code: "facet.group.${group.key}", default: "${group.key}"))
                            }
                        }
                        td(alatag.databaseFieldName(text: field.name))
                        td(field.raw)
                        td(field.processed)
                    }
                }
            }
        }
    }

    /**
     * Camel case converted, taken from JS code:
     *
     * str.replace(/([a-z])([A-Z])/g, "$1 $2").toLowerCase().capitalize();
     *
     * @attr text REQUIRED the input text
     */
    def camelCaseToHuman = { attrs ->
        String text = attrs.text
        text = text.replaceAll(/([a-z])([A-Z])/, '$1 $2').toLowerCase().capitalize()
        out << text.replaceAll("_", " ")
    }

    /**
     * Database field names align with download field names so they be in i18n with or without .p appended.
     *
     * Download field name values in i18n may end with a distinction between raw and processed that occurs after '-'
     *
     * @attr text REQUIRED the input text
     */
    def databaseFieldName = { attrs ->
        String text = attrs.text
        text = alatag.message(code:text, default: alatag.message(code:text + '.p', default:alatag.camelCaseToHuman(text: text)))
        out << text.replaceAll(/-.*/, '')
    }

    /**
     * Get the DRUID
     *
     * @attr uuid REQUIRED the record object (JsonObject)
     */
    def getDruid = { attrs ->
        def uuid = attrs.uuid

        def record = webServicesService.getRecord(uuid, false)
        def druid = record?.raw?.attribution?.dataResourceUid

        out << druid
    }

    /**
     * Generate an occurrence table row
     *
     * @attr fieldName REQUIRED
     * @attr fieldNameIsMsgCode
     * @attr fieldCode
     * @attr section REQUIRED
     * @attr annotate REQUIRED
     * @attr path
     * @attr guid
     */
    def occurrenceTableRow = { attrs, body ->
        String bodyText = (String) body()
        def guid = attrs.guid
        def path = attrs.path
        def fieldCode = attrs.fieldCode
        def fieldName = attrs.fieldName
        def fieldNameIsMsgCode = attrs.fieldNameIsMsgCode
        def userDetails

        if(fieldCode == 'transcriber'){
            userDetails = userService.detailsForUserId(bodyText)
            bodyText = userDetails.displayName
        }

        if (StringUtils.isNotBlank(bodyText)) {

            def link = (guid) ? "${path}${guid}" : ""
            def mb = new MarkupBuilder(out)

            mb.tr(id:"${fieldCode}") {
                td(class:"dwcLabel " + fieldCode) {
                    mkp.yieldUnescaped(formatFieldName(fieldCode, fieldName))
                }
                td(class:"value") {
                    if (link) {
                        a(href: link) {
                            mkp.yieldUnescaped(bodyText)
                        }
                    } else {
                        // allow sanitized HTML to be rendered in output
                        mkp.yieldUnescaped(sanitizeBodyText(bodyText, true))
                    }
                }
            }
        }
    }

    /**
     * Create a link for a userId and dataResourceUid combination
     * E.g. <a href="${grailsApplication.config.sightings.baseUrl}/spotter/${record.raw.occurrence.userId}">${record.alaUserName}</a>
     *
     * @attr userName REQUIRED
     * @attr userId
     * @attr dataResourceUid REQUIRED
     * @attr occurrenceId
     * @attr openInNewWindow
     */
    def getLinkForUserId = { attrs ->
        def userName = attrs.userName
        def userId = attrs.userId
        def dataResourceUid = attrs.dataResourceUid
        String occurrenceId = attrs.occurrenceId
        def url

        if (userName) {
            if (dataResourceUid == grailsApplication.config.getProperty('dataResourceUuid.alaSightings', String,'')) {
                // ALA sightings
                url = "<a href=\"${grailsApplication.config.getProperty("sightings.baseUrl")}/spotter/${userId.encodeAsURL()}\">${userName}</a>"
            } else if (dataResourceUid == grailsApplication.config.getProperty('dataResourceUuid.iNaturalist', String,'')) {
                // iNaturalist
                url = "<a href=\"${grailsApplication.config.getProperty( "iNaturalist.baseUrl", "https://inaturalist.org")}/people/${userId.encodeAsURL()}\">${userName}</a>"
            } else if (dataResourceUid == grailsApplication.config.getProperty('dataResourceUuid.flickr', String,'') && occurrenceId) {
                // Flickr
                // Munge occurrenceId to get the URL, as we don't have the user-name stored in biocache in order to generate it
                // e.g. https://www.flickr.com/photos/dhobern/5466675452/ to https://www.flickr.com/photos/dhobern/
                String flickId = occurrenceId.replaceAll("^https:\\/\\/www\\.flickr\\.com\\/photos\\/(.*?)\\/\\d+\\/", '$1')
                url = "<a href=\"https://www.flickr.com/photos/${flickId}\">${userName}</a>"
            } else {
                url = userName // pass-through
            }
        } else if (userId) {
            url = userId // pass-through
        }

        out << url
    }

    /**
     * Generate a compare record "row"
     *
     * @attr compareRecord REQUIRED
     * @attr fieldsMap REQUIRED
     * @attr group REQUIRED
     * @attr exclude REQUIRED
     */
    def formatExtraDwC = { attrs ->
        def compareRecord = attrs.compareRecord
        Map fieldsMap = attrs.fieldsMap
        def group = attrs.group
        def exclude = attrs.exclude?:''
        def output = ""

        def excludeList = exclude.toString().toLowerCase().split(",")

        compareRecord.get(group).each { cr ->
            def key = cr.name
            def label = message(code:key, default:"") ?: camelCaseToHuman(text: key) ?: StringUtils.capitalize(key)

            // only output fields not already included (by checking fieldsMap Map) && not in excluded list
            if (!fieldsMap.containsKey(key) && !excludeList.contains(key.toLowerCase())) {
                //def mb = new MarkupBuilder(out)
                def tagBody

                if (cr.processed && cr.raw && cr.processed == cr.raw) {
                    tagBody = pipeWhitespace(cr.processed)
                } else if (!cr.raw && cr.processed) {
                    tagBody = pipeWhitespace(cr.processed)
                } else if (cr.raw && !cr.processed) {
                    tagBody = pipeWhitespace(cr.raw)
                } else {
                    tagBody = "${pipeWhitespace(cr.processed)} <br/><span class='originalValue'>${alatag.message(code:"alatag.supplied.as")} ${cr.raw}</span>"
                }
                output += occurrenceTableRow(annotate:"true", section:"dataset", fieldCode:"${key}", fieldName:"${label}") {
                    tagBody
                }
            }
        }
        out << output
    }

    def pipeWhitespace(str) {
        // inject whitespace around pipe
        str.replaceAll("(?<=\\S)\\|(?=\\S)", " | ")
    }

    def formatDynamicLabel(str){
        if(str){
           str.substring(0, str.length() - 2).replaceAll("_", " ")
        } else {
            str
        }
    }

    /**
     * Output a row (occurrence record) in the search results "Records" tab
     *
     * @attr occurrence REQUIRED
     */
    def formatListRecordRow = { attrs ->

        def occurrence = attrs.occurrence
        def mb = new MarkupBuilder(out)
        def outputResultsLabel = { cssClass, label, value, test ->
            if (test) {
                mb.span(class:'resultValue ' + cssClass) {
                    span(class:'resultsLabel') {
                        mkp.yieldUnescaped(label + ": ")
                    }
                    mkp.yieldUnescaped(value)
                }
            }
        }

        def outputDynamicResultsLabel = { label, value, test ->
            if (test) {
                mb.span(class:'resultValue ' + label) {
                    span(class:'resultsLabel') {
                        mkp.yieldUnescaped(formatDynamicLabel(label))
                    }
                    span(class:'resultsValue'){
                        mkp.yieldUnescaped(value)
                    }
                }
            }
        }

        mb.div(class:'recordRow', id:occurrence.uuid ) {
            p(class:'rowA') {
                if (occurrence.taxonRank && occurrence.scientificName) {
                    span(style:'text-transform: capitalize', alatag.message(code:"rank."+occurrence.taxonRank, default: occurrence.taxonRank))
                    mkp.yieldUnescaped(":&nbsp;")
                    span(class:'occurrenceNames') {
                        mkp.yieldUnescaped(alatag.formatSciName(rankId:occurrence.taxonRankID?:'6000', name:"${occurrence.scientificName}"))
                    }
                } else if(occurrence.raw_scientificName){
                    span(class:'occurrenceNames', occurrence.raw_scientificName)
                }

                if (grailsApplication.config.getProperty('vernacularName.show', Boolean, true) && occurrence.vernacularName || occurrence.raw_vernacularName) {
                    mkp.yieldUnescaped("&nbsp;|&nbsp;")
                    span(class:'occurrenceNames', occurrence.vernacularName?:occurrence.raw_vernacularName)
                }

                span(class:'eventAndLocation') {
                    if (occurrence.eventDate) {
                        outputResultsLabel('eventdate', alatag.message(code:"record.eventdate.label"), g.formatDate(date: new Date(occurrence.eventDate), format:"yyyy-MM-dd"), true)
                    } else if (occurrence.year) {
                        outputResultsLabel('year', alatag.message(code:"record.year.label"), occurrence.year, true)
                    }
                    if (occurrence.stateProvince) {
                        outputResultsLabel('state', alatag.message(code:"record.state.label"), alatag.message(code:occurrence.stateProvince), true)
                    } else if (occurrence.country) {
                        outputResultsLabel('country', alatag.message(code:"record.country.label"), alatag.message(code:occurrence.country), true)
                    }
                }

                // display dynamic fields
                if(grailsApplication.config.getProperty('table.displayDynamicProperties', Boolean, false)) {
                    span(class: 'dynamicValues') {
                        def count = 0
                        occurrence.miscStringProperties.each { key, value ->
                            if (count < maxDynamicProperties) {
                                if(value && value.length < maxDynamicPropertyLength) {
                                    outputDynamicResultsLabel(key + ": ", value, true)
                                }
                                count++
                            }
                        }
                        occurrence.miscIntProperties.each { key, value ->
                            if (count < maxDynamicProperties) {
                                outputDynamicResultsLabel(key + ": ", value, true)
                                count++
                            }
                        }
                        occurrence.miscDoubleProperties.each { key, value ->
                            if (count < maxDynamicProperties) {
                                outputDynamicResultsLabel(key + ": ", value, true)
                                count++
                            }
                        }
                    }
                }
            }

            p(class:'rowB') {
                outputResultsLabel('institutionName', alatag.message(code:"record.institutionName.label"), alatag.message(code:occurrence.institutionName), occurrence.institutionName)
                outputResultsLabel('collectionName', alatag.message(code:"record.collectionName.label"), alatag.message(code:occurrence.collectionName), occurrence.collectionName)
                outputResultsLabel('dataResourceName', alatag.message(code:"record.dataResourceName.label"), alatag.message(code:occurrence.dataResourceName), !occurrence.collectionName && occurrence.dataResourceName)
                outputResultsLabel('basisofrecord', alatag.message(code:"record.basisofrecord.label"), alatag.message(code:occurrence.basisOfRecord), occurrence.basisOfRecord)
                outputResultsLabel('catalognumber', alatag.message(code:"record.catalogNumber.label"), "${occurrence.raw_collectionCode ? occurrence.raw_collectionCode + ':' : ''}${occurrence.raw_catalogNumber}", occurrence.raw_catalogNumber)
                a(
                        href: g.createLink(url:"${request.contextPath}/occurrences/${occurrence.uuid}"),
                        class:"occurrenceLink",
                        alatag.message(code:"record.view.record")
                )
            }
        }
    }

    /**
     * Alternative to g.message(code:'foo.bar')
     *
     * @see org.grails.plugins.web.taglib.ValidationTagLib
     *
     * @attr code REQUIRED
     * @attr default
     */
    def message = { attrs ->
        def code = attrs.code?.toString() // in case a G-sting
        def output = ""

        if (code) {
            String defaultMessage
            if (attrs.containsKey('default')) {
                defaultMessage = attrs['default']?.toString()
            } else {
                defaultMessage = code
            }

            Map messagesMap = messageSourceCacheService.getMessagesMap(RequestContextUtils.getLocale(request)) // g.message too slow so we use a Map instead
            def message = messagesMap.get(code)
            output = message ?: defaultMessage
        }

        return output
    }

    /**
     * Display the logged in user (user id)
     */
    def loggedInUserId = { attrs ->
        out << authService?.userId
    }

    /**
     * Display the logged in user (display name)
     */
    def loggedInUserDisplayname = { attrs ->
        out << (authService?.displayName?:authService?.email)
    }

    /**
     * Display the logged in user (email)
     */
    def loggedInUserEmail = { attrs ->
        out << authService?.email
    }

    /**
     * Get the list of available reason codes and labels from the Logger app
     *
     * Note: outputs an Object and thus needs:
     *
     *   static returnObjectForTags = ['getLoggerReasons']
     *
     * at top of taglib
     */
    def getLoggerReasons = { attrs ->
        try {
            return webServicesService.getLoggerReasons()
        } catch (Exception e) {
            log.error("Failed to get logger reasons: ${e.message}", e)
            return [[id: "-1", name: "Error. Failed to retrieve logger reasons codes, see logs for details."]]
        }
    }

    /**
     * Get the appropriate sourceId for the current hub
     */
    def getSourceId = { attrs ->
        def skin = grailsApplication.config.getProperty('skin.layout')?.toUpperCase()
        try {
            def sources = webServicesService.getLoggerSources()
            sources.each {
                if (it.name == skin) {
                    out << it.id
                }
            }
        } catch (Exception e) {
            log.error("Failed to get logger sources: ${e.message}", e)
        }
    }

    /**
     * Display an outage banner
     */
    def outageBanner = { attrs ->
        def message = "Outage banner no longer supported - please use ala-admin-plugin tag - <code>&lt;ala:systemMessage/&gt;</code> and remove <code>&lt;alatag:outageBanner/&gt;</code>"

        if (message) {
            out << "<div id='outageMessage'>" + message + "</div>"
        }
    }

    /**
     *
     * @attr msg REQUIRED
     * @attr level
     */
    def logMsg = { attrs ->
        log."${attrs.level?:'info'}" attrs.msg
    }

    /**
     * Determine the URL prefix for biocache-service AJAX calls. Looks at the
     * biocache.ajax.useProxy config var to see whether or not to use the proxy
     */
    def getBiocacheAjaxUrl = { attrs ->
        String url = grailsApplication.config.getProperty('biocache.baseUrl')
        Boolean useProxy = grailsApplication.config.getProperty('biocache.ajax.useProxy', Boolean) // will convert String 'true' to boolean true
        log.debug "useProxy = ${useProxy}"

        if (useProxy) {
            url = g.createLink(uri: '/proxy')
        }

        out << url
    }

    /**
     * Generate a query string for the remove spatial filter link
     */
    def getQueryStringForWktRemove = { attr ->
        def paramsCopy = params.clone()
        paramsCopy.remove("wkt")
        paramsCopy.remove("action")
        paramsCopy.remove("controller")
        def queryString = MoreWebUtils.toQueryString(paramsCopy)
        log.debug "queryString = ${queryString}"
        out << queryString
    }

    def linkViewOriginal = { attr, body ->
        if (isValidUrl(attr.url)) {
            out << g.link(attr, body)
        } else {
            out << ""
        }
    }

    boolean isValidUrl(String URL) {
        def url = null
        try {
            url = new java.net.URL(URL)
        } catch(e) {
            return false
        }
        return url?.getProtocol() == 'http' || url?.getProtocol() == 'https'
    }

    def getQueryStringForRadiusRemove = { attr ->
        def paramsCopy = params.clone()
        paramsCopy.remove("lat")
        paramsCopy.remove("lon")
        paramsCopy.remove("radius")
        paramsCopy.remove("action")
        paramsCopy.remove("controller")
        def queryString = MoreWebUtils.toQueryString(paramsCopy)
        log.debug "queryString = ${queryString}"
        out << queryString
    }

    /**
     * Output the meta tags (HTML head section) for the build meta data in application.properties
     * E.g.
     * <meta name="svn.revision" content="${g.meta(name:'svn.revision')}"/>
     * etc.
     *
     * Updated to use properties provided by build-info plugin
     */
    def addApplicationMetaTags = { attrs ->
        // def metaList = ['svn.revision', 'svn.url', 'java.version', 'java.name', 'build.hostname', 'app.version', 'app.build']
        def metaList = ['app.version', 'app.grails.version', 'build.date', 'scm.version', 'environment.BUILD_NUMBER', 'environment.BUILD_ID', 'environment.BUILD_TAG', 'environment.GIT_BRANCH', 'environment.GIT_COMMIT']
        def mb = new MarkupBuilder(out)

        mb.meta(name:'grails.env', content: "${Environment.current}")
        metaList.each {
            mb.meta(name:it, content: g.meta(name: it)?: '' )
        }
        mb.meta(name:'java.version', content: "${System.getProperty('java.version')}")
    }

    /**
     * A little bit of email scrambling for dumb scrappers.
     *
     * Uses email attribute as email if present else uses the body.
     * If no attribute and the body is not an email address then nothing is shown.
     *
     * @attrs email the address to decorate
     * @body the text to use as the link text
     */
    def emailLink = { attrs, body ->
        def strEncodedAtSign = "(SPAM_MAIL@ALA.ORG.AU)"
        String email = attrs.email
        if (!email)
            email = body().toString()
        int index = email.indexOf('@')
        if (index > 0) {
            email = email.replaceAll("@", strEncodedAtSign)
            out << "<a href='#' class='link under' onclick=\"return sendEmail('${email}')\">${body()}</a>"
        }
    }

    /**
     * Take a block of content with suspected HTML elements (to be outputted) and
     * sanitizes the HTML to prevent XSS and breaking of DOM due to missing closing tags, etc.
     *
     * @body content the text to use as the link text
     */
    def sanitizeContent = { attrs, body ->
        String bodyText = (String) body()
        out << sanitizeBodyText(bodyText)
    }

    /**
     * Utility to sanitise HTML text and only allow links to be kept, removing any
     * other HTML markup. Links get <code>target="_blank"</code> added unless
     * <code>openInNewWindow</code> is set to false.
     *
     * @param input HTML String
     * @param openInNewWindow Boolean default to to true
     * @return output sanitized HTML String
     */
    String sanitizeBodyText(String input, Boolean openInNewWindow = true) {
        // text with HTML tags will be escaped, so first we need to unescape it
        String unescapedHtml =  StringEscapeUtils.unescapeHtml(input)
        // Sanitize the HTML and only allow links with valid URLs, span and br tags
        PolicyFactory policy = new HtmlPolicyBuilder()
                .allowElements("a")
                .allowElements("br")
                .allowElements("i")
                .allowElements("b")
                .allowElements("span")
                .allowStandardUrlProtocols()
                .allowAttributes("href").matching(Pattern.compile("^(/|http|https|mailto).+", Pattern.CASE_INSENSITIVE))
                .onElements("a")
                .requireRelNofollowOnLinks()
                .allowAttributes("class").onElements("span")
                .allowAttributes("id").onElements("span")
                .toFactory()
        String sanitizedHtml = policy.sanitize(unescapedHtml)

        if (openInNewWindow) {
            // hack to force links to be opened in new window/tab
            sanitizedHtml =  sanitizedHtml.replaceAll("<a ", "<a target=\"_blank\" ")
        }

        sanitizedHtml
    }

    /**
     * Remove any text containing the apiKey value from the UI
     *
     * @attr message REQUIRED
     */
    def stripApiKey = { attrs, body ->
        String message = attrs.message
        String output = message.replaceAll(/apiKey=[a-z0-9_\-]*/, "")
        log.debug "stripApiKey input = ${message}"
        log.debug "stripApiKey output = ${output}"
        out << output
    }

    @Value('${dataquality.enabled}')
    Boolean dataQualityEnabled

    def ifDataQualityEnabled = { attrs, body ->
        if (dataQualityEnabled) {
            out << body()
        }
    }

    def invertQualityCategory = { attrs, body ->
        QualityCategory category = attrs.remove('category')
        Map<String,String> inverseFilters = attrs.remove('inverseFilters')

        GrailsParameterMap newParams = params.clone()
        List<String> existingFilters = newParams.list('fq')

        def inverseFilter
        if (inverseFilters) {
            inverseFilter = inverseFilters[category.label]
        } else {
            inverseFilter = time("getInverseCategoryFilter") { qualityService.getInverseCategoryFilter(category) }
        }
        if (inverseFilter) {
            existingFilters += inverseFilter
        }
        newParams.disableAllQualityFilters = true
        newParams.fq = existingFilters

        attrs['class'] = (attrs['class'] as Set) + 'inverse-filter-link'

        if (!attrs.action) {
            attrs.action = actionName
        }
        newParams.remove('startIndex')
        newParams.remove('offset')
        newParams.remove('max')
        attrs.params = newParams

        out << g.link(attrs, body)
    }

    def createInverseQualityCategoryLink = { attrs, body ->
        QualityCategory category = attrs.remove('category')
        Map<String,String> inverseFilters = attrs.remove('inverseFilters')

        GrailsParameterMap newParams = params.clone()
        List<String> existingFilters = newParams.list('fq')

        def inverseFilter
        if (inverseFilters) {
            inverseFilter = inverseFilters[category.label]
        } else {
            inverseFilter = time("getInverseCategoryFilter") { qualityService.getInverseCategoryFilter(category) }
        }
        if (inverseFilter) {
            existingFilters += inverseFilter
        }
        newParams.disableAllQualityFilters = true
        newParams.fq = existingFilters

        if (!attrs.action) {
            attrs.action = actionName
        }
        newParams.remove('startIndex')
        newParams.remove('offset')
        newParams.remove('max')
        attrs.params = newParams

        out << g.createLink(attrs, body)
    }

    /**
     * Convert a data quality category into user filter queries or vice versa
     *
     * @attr category REQUIRED The QualityCategory to enable/disable in the link
     * @attr enable REQUIRED Whether to enable or disable the QualityCategory in this link
     * @attr expand REQUIRED Whether to expand (or contract) the QualityCategory into individual filter queries
     */
    def linkQualityCategory = { attrs, body ->

        QualityCategory category = attrs.remove('category')
        boolean enable = attrs.remove('enable')
        boolean expand = attrs.remove('expand')

        GrailsParameterMap newParams = params.clone()
        List<String> disables
        if (enable) {
            disables = params.list('disableQualityFilter') - category.label
        } else {
            disables = params.list('disableQualityFilter') + category.label
        }
        if (expand) {
            List<String> filters
            if (enable) {
                List<String> existingFilters = new ArrayList<String>(params.list('fq'))
                List<String> removedFilters = category.qualityFilters.findAll { it.enabled }*.filter
                // TODO O(mn)
                removedFilters.each { existingFilters.remove(it) }
                filters = existingFilters
            }
            else {
                filters = params.list('fq') + category.qualityFilters.findAll { it.enabled }*.filter
            }

            if (filters) {
                newParams.fq = filters
            } else {
                newParams.remove('fq')
            }
        }
        if (disables) {
            newParams.disableQualityFilter = disables
        } else {
            newParams.remove('disableQualityFilter')
        }

        if (!attrs.action) {
            attrs.action = actionName
        }
        newParams.remove('startIndex')
        newParams.remove('offset')
        newParams.remove('max')
        attrs.params = newParams

        out << g.link(attrs, body)
    }

    def linkToggeleDQFilters = { attrs ->
        GrailsParameterMap newParams = params.clone()
        def cap = ""
        if (params.disableAllQualityFilters) {
            attrs.title = 'Click to re-enable Data Quality filters'
            cap = 'Enable Quality filters'
            newParams.remove('disableAllQualityFilters')
        } else {
            attrs.title = 'Click to disable All Data Quality filters'
            cap = 'Disable All Quality filters'
            newParams.put('disableAllQualityFilters', true)
        }

        if (!attrs.action) {
            attrs.action = actionName
        }

        attrs.params = newParams

        out << g.link(attrs, cap)
    }

    def linkResetSearch = { attrs, body ->
        def filters =  attrs.remove('filters')

        GrailsParameterMap newParams = params.clone()
        newParams.remove('disableQualityFilter')
        newParams.remove('disableAllQualityFilters')
        newParams.remove('qualityProfile')

        def newfq = params.list('fq').findAll {!filters.contains(it)}
        if (newfq.size() > 0) {
            newParams.fq = newfq
        } else {
            newParams.remove('fq')
        }
        newParams.remove('startIndex')
        newParams.remove('offset')
        newParams.remove('max')

        if (!attrs.action) {
            attrs.action = actionName
        }
        attrs.params = newParams

        out << g.link(attrs, body)
    }

    def resultCount = { attrs, body ->
        def mb = new MarkupBuilder(out)

        if (dataQualityEnabled) {
            mb.span(id:'returnedText') {
                strong g.formatNumber(number: "${attrs.totalRecords}", format: "#,###,###")
                span alatag.message(code: "list.resultsreturned.span.returnedtotal", default: 'records returned of')
                strong g.formatNumber(number: "${attrs.qualityTotalCount}", format:"#,###,###")
                span alatag.message(code:"list.resultsreturned.span.returnedtext", default:'for')
            }
        } else {
            mb.span(id:'returnedText') {
                strong g.formatNumber(number: "${attrs.totalRecords}", format: "#,###,###")
                span alatag.message(code:"list.resultsreturned.span.returnedtext1", default:'results for')
            }
        }
    }
}

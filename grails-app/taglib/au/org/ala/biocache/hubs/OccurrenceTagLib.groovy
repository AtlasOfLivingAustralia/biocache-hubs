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

import groovy.xml.MarkupBuilder
import org.apache.commons.lang.StringUtils
import org.apache.commons.lang.time.DateUtils
import org.codehaus.groovy.grails.web.json.JSONObject

import java.text.SimpleDateFormat

class OccurrenceTagLib {
    //static defaultEncodeAs = 'html'
    //static encodeAsForTags = [tagName: 'raw']
    static returnObjectForTags = ['getLoggerReasons']
    def webServicesService, authService, outageService
    static namespace = 'alatag'     // namespace for headers and footers

    /**
     * Formats the display of dynamic facet names in Sandbox (facet options popup)
     *
     * @attr fieldName REQUIRED the field name
     */
    def formatDynamicFacetName = { attrs ->
        log.debug "formatDynamicFacetName - ${session['hit']++}"
        def fieldName = attrs.fieldName
        def output
        if (fieldName.endsWith('_s') || fieldName.endsWith('_i') || fieldName.endsWith('_d')) {
            output = fieldName.substring(0,-2).replaceAll("_", " ")
        } else if (fieldName.endsWith('_RNG')) {
            output = fieldName.substring(0,-4).replaceAll("_", " ") + " (range)"
        } else {
            output = "${g:message(code:"facet.${fieldName}", default: fieldName)}"
        }

        out << output
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
        def rankId = attrs.rankId.toInteger()
        def acceptedNameOutput = ""
        def nameOutput = ""
        def ital = ["",""]

        if (!rankId || rankId >= 6000) {
            ital = ["<i>","</i>"]
        }

        if (acceptedName) {
            acceptedNameOutput = " (accepted name: ${ital[0]}${acceptedName}${ital[1]})"
        }

        nameOutput = "${ital[0]}${name}${ital[1]}${acceptedNameOutput}"

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

    /**
     * Generate HTML for current filters
     *
     * @attr item REQUIRED
     * @attr addCheckBox Boolean
     * @attr cssClass String
     * @attr addCloseBtn Boolean
     */
    def currentFilterItem = { attrs ->
        def item = attrs.item
        def filterLabel = item.value.displayName.replaceFirst(/^\-/, "") // remove leading "-" for exclude searches
        def preFix = (item.value.displayName.startsWith('-')) ? "<span class='excludeFq'>[exclude]</span> " : ""
        def fqLabel = preFix + filterLabel

        def mb = new MarkupBuilder(out)
        mb.a(   href:"#",
                class: "${attrs.cssClass} tooltips activeFilter",
                    title: message(code:"title.filter.remove", default:"Click to remove this filter"),
                    "data-facet": item.key
                    //"data-facet":"${item.key}:${item.value.value.encodeAsURL()}",
                    //onClick:"removeFacet(this); return false;"
            ) {
            if (attrs.addCheckBox) {
                span(class:'checkbox-checked') {
                    mkp.yieldUnescaped("&nbsp;")
                }
            }
            if (item.key.contains("occurrence_year")) {
                fqLabel = fqLabel.replaceAll(':',': ').replaceAll('occurrence_year', message(code: 'facet.occurrence_year', default:'occurrence_year'))
                mkp.yieldUnescaped( fqLabel.replaceAll(/(\d{4})\-.*?Z/) { all, year ->
                    def year10 = year.toInteger() + 10
                    "${year} - ${year10}"
                })
            } else {
                mkp.yieldUnescaped(message(code: fqLabel, default: fqLabel).replaceFirst(':',': '))
            }
            if (attrs.addCloseBtn) {
                mkp.yieldUnescaped("&nbsp;")
                span(class:'closeX') {
                    mkp.yieldUnescaped("&times;")
                }
            }
        }
    }

    /**
     *  Generate facet links in the left hand column
     *
     */
    def facetLinkList = { attrs ->
        def facetResult = attrs.facetResult
        def queryParam = attrs.queryParam
        def mb = new MarkupBuilder(out)
        //def fqValue = fieldResult.label?.encodeAsURL()
        def linkTitle = "Filter results by ${alatag.formatDynamicFacetName(fieldName:facetResult.fieldName)}"

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
                // Catch specific facets fields
                if (fieldResult.fq) {
                    // biocache-service has provided a fq field in the fieldResults list
                    li {
                        a(      href:"?${queryParam}&fq=${fieldResult.fq?.encodeAsURL()}",
                                class: "tooltips",
                                title: linkTitle
                        ) {
                            span(class:"checkbox-unchecked"){
                                mkp.yieldUnescaped("&nbsp;")
                            }
                            span(class:"facet-item") {
                                mkp.yield(message(code:"${fieldResult.label?:'unknown'}", default:"${fieldResult.label}"))
                                addCounts(fieldResult.count)
                            }

                        }

                    }
                } else if (facetResult.fieldName.startsWith("occurrence_")) {
                    // decade date range a special case
                    def decade = processDecadeLabel(facetResult.fieldName, facetResult.fieldResult?.get(1)?.label, fieldResult.label)

                    li {
                        a(      href:"?${queryParam}&fq=${decade.fq}",
                                class: "tooltips",
                                title: linkTitle
                        ) {
                            span(class:"checkbox-unchecked"){
                                mkp.yieldUnescaped("&nbsp;")
                            }
                            span(class:"facet-item") {
                                mkp.yieldUnescaped("${decade.label}")
                                addCounts(fieldResult.count)
                            }
                        }

                    }
                } else {
                    def label = g.message(code:"${facetResult.fieldName}.${fieldResult.label}", default:"")?:
                            g.message(code:"${fieldResult.label?:'unknown'}", default:"${fieldResult.label}")
                    li {
                        a(      href:"?${queryParam}&fq=${facetResult.fieldName}:%22${fieldResult.label?.encodeAsURL()}%22",
                                class: "tooltips",
                                title: linkTitle
                        ) {
                            span(class:"checkbox-unchecked"){
                                mkp.yieldUnescaped("&nbsp;")
                            }
                            span(class:"facet-item") {
                                mkp.yield(label)
                                addCounts(fieldResult.count)
                            }
                        }
                    }
                }
            }
        }
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
            output.startYear = "Before "
            output.endDate = firstLabel
            output.endYear = output.endDate?.substring(0, 4)
        } else {
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
            recordId = record.raw.occurrence.collectionCode + " - " + record.raw.occurrence.catalogNumber
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
                mkp.yield(g.message(code: "${assertion.name}", default :"${assertion.name}"))

                if (assertion.assertionByUser) {
                    br()
                    strong() {
                        mkp.yield(" (added by you")
                        if (assertion.users?.size() > 1) {
                            mkp.yield(" and ${assertion.users.size() - 1} other user${(assertion.users.size() > 2) ? 's':''})")
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
            i(class:"icon-question-sign", "")
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
                                b(group.key)
                            }
                        }
                        td(alatag.camelCaseToHuman(text: field.name))
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
        out << text.replaceAll(/([a-z])([A-Z])/, '$1 $2').toLowerCase().capitalize()
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

        if (StringUtils.isNotBlank(bodyText)) {
            def link = (guid) ? "${path}${guid}" : ""
            def mb = new MarkupBuilder(out)

            mb.tr(id:"${fieldCode}") {
                td(class:"dwcLabel") {
                    if (fieldNameIsMsgCode) {
                        mkp.yield(g.message(code: "${fieldName}", default :"${fieldName}"))
                    } else {
                        mkp.yieldUnescaped(fieldName)
                    }

                }
                td(class:"value") {
                    if (link) {
                        a(href: link) {
                            mkp.yieldUnescaped(bodyText)
                        }
                    } else {
                        mkp.yieldUnescaped(bodyText)
                    }
                }
            }
        }
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

        compareRecord.get(group).each { cr ->
            def key = cr.name
            def label = g.message(code:key, default:"")?:alatag.camelCaseToHuman(text: key)?:StringUtils.capitalize(key)

            // only output fields not already included (by checking fieldsMap Map) && not in excluded list
            if (!fieldsMap.containsKey(key) && !StringUtils.containsIgnoreCase(exclude, key)) {
                //def mb = new MarkupBuilder(out)
                def tagBody

                if (cr.processed && cr.raw && cr.processed == cr.raw) {
                    tagBody = cr.processed
                } else if (!cr.raw && cr.processed) {
                    tagBody = cr.processed
                } else if (cr.raw && !cr.processed) {
                    tagBody = cr.raw
                } else {
                    tagBody = "${cr.processed} <br/><span class='originalValue'>Supplied as ${cr.raw}</span>"
                }
                output += alatag.occurrenceTableRow(annotate:"true", section:"dataset", fieldCode:"${key}", fieldName:"<span class='dwc'>${label}</span>") {
                    tagBody
                }
            }
        }
        out << output
    }

    /**
     * Output a row (occurrence record) in the search results "Records" tab
     *
     * @attr occurrence REQUIRED
     */
    def formatListRecordRow = { attrs ->
        log.debug "formatListRecordRow - ${session['hit']++}"
        def JSONObject occurrence = attrs.occurrence
        def mb = new MarkupBuilder(out)

        def outputResultsLabel = { label, value, test ->
            if (test) {
                mb.span(style:'text-transform: capitalize;') {
                    strong(class:'resultsLabel') {
                        mkp.yieldUnescaped(label)
                    }
                    mkp.yieldUnescaped(value)
                }
            }
        }

        mb.div(class:'recordRow', id:occurrence.uuid ) {
            p(class:'rowA') {
                if (occurrence.taxonRank && occurrence.scientificName) {
                    span(style:'text-transform: capitalize', occurrence.taxonRank)
                    mkp.yieldUnescaped(":&nbsp;")
                    span(class:'occurrenceNames') {
                        mkp.yieldUnescaped(alatag.formatSciName(rankId:occurrence.taxonRankID?:'6000', name:"${occurrence.scientificName}"))
                    }
                } else {
                    span(class:'occurrenceNames', occurrence.raw_scientificName)
                }
                if (occurrence.vernacularName || occurrence.raw_vernacularName) {
                    mkp.yieldUnescaped(":&nbsp;|&nbsp;")
                    span(class:'occurrenceNames', occurrence.vernacularName?:occurrence.raw_vernacularName)
                }
                span(style:'margin-left: 8px;') {
                    if (occurrence.eventDate) {
                        outputResultsLabel("Date: ", g.formatDate(number:"${occurrence.eventDate}", format:"yyyy-MM-dd"), true)
                    } else if (occurrence.occurrenceYear) {
                        outputResultsLabel("Year: ", g.formatDate(number:"${occurrence.occurrenceYear}", format:"yyyy"), true)
                    }
                    if (occurrence.stateProvince) {
                        outputResultsLabel("State: ", message(code:occurrence.stateProvince), true)
                    } else if (occurrence.country) {
                        outputResultsLabel("Country: ", message(code:occurrence.country), true)
                    }
                }
            }
            p(class:'rowB') {
                outputResultsLabel("Institution: ", message(code: occurrence.institutionName), occurrence.institutionName)
                outputResultsLabel("Collection: ", message(code: occurrence.collectionName), occurrence.collectionName)
                outputResultsLabel("Data&nbsp;Resource: ", message(code:occurrence.dataResourceName), !occurrence.collectionName && occurrence.dataResourceName)
                outputResultsLabel("Basis&nbsp;of&nbsp;record: ", message(code: occurrence.basisOfRecord), occurrence.basisOfRecord)
                outputResultsLabel("Catalog&nbsp;number: ", "${occurrence.raw_collectionCode}:${occurrence.raw_catalogNumber}", occurrence.raw_catalogNumber!= null && occurrence.raw_catalogNumber)
                a(
                        href: g.createLink(url:"${request.contextPath}/occurrences/${occurrence.uuid}"),
                        class:"occurrenceLink",
                        style:"margin-left: 15px;",
                        "View record"
                )
            }
        }
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
        out << (authService?.displayName?:authService.email)
    }

    /**
     * Display the logged in user (email)
     */
    def loggedInUserEmail = { attrs ->
        out << authService.email
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
        webServicesService.getLoggerReasons()
    }

    /**
     * Get the appropriate sourceId for the current hub
     */
    def getSourceId = { attrs ->
        def skin = grailsApplication.config.skin.name?.toUpperCase()
        def sources = webServicesService.getLoggerSources()
        sources.each {
            if (it.name == skin) {
                out << it.id
            }
        }
    }

    /**
     * Display an outage banner
     */
    def outageBanner = { attrs ->
        OutageBanner ob = outageService.getOutageBanner()

        if (ob.message) {
            String message = ob.getMessage()
            Date now = new Date()
            Date start = new SimpleDateFormat("yyyy-MM-dd", Locale.ENGLISH).parse(ob.startDate);
            Date end = new SimpleDateFormat("yyyy-MM-dd", Locale.ENGLISH).parse(ob.endDate);

            if (ob.getShowMessage() != null && ob.getShowMessage()) {
                // showMessage is checked
                // Do a date comparison to see if today is between the startDate and endDate (inclusive)
                if (DateUtils.isSameDay(now, start) || now.after(start)) {
                    if (DateUtils.isSameDay(now, end) || now.before(end)) {
                        // output the banner message
                        out << "<div id='outageMessage'>" + message + "</div>"
                    } else {
                        log.debug("now is not on or before endDate")
                    }
                } else {
                    log.debug("now is not on or after startDate")
                }
            }
        }
    }

    /**
     *
     * @attr msg REQUIRED
     * @attr level
     */
    def logMsg = { attrs ->
        log."${attrs.level?:'error'}" attrs.msg
    }
}

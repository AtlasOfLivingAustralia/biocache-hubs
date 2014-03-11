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

class OccurrenceTagLib {
    //static defaultEncodeAs = 'html'
    //static encodeAsForTags = [tagName: 'raw']
    static returnObjectForTags = ['getLoggerReasons']
    def webServicesService, authService
    static namespace = 'alatag'     // namespace for headers and footers

    /**
     * Formats the display of dynamic facet names in Sandbox (facet options popup)
     *
     * @attr fieldName REQUIRED the field name
     */
    def formatDynamicFacetName = { attrs ->
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
     */
    def currentFilterItem = { attrs ->
        def item = attrs.item
        def filterLabel = alatag.formatDynamicFacetName(fieldName: item.value.displayName)
        def fqLabel = (filterLabel.startsWith('-')) ? "<span class=\"red\">[exclude]</span> ${filterLabel.substring(1, filterLabel.size())}" : filterLabel

        def mb = new MarkupBuilder(out)
        mb.li() {
            a(      href:"#",
                    class: "tooltips",
                    title: "remove filter",
                    "data-facet":"${item.key}:${item.value.value.encodeAsURL()}",
                    onClick:"removeFacet(this); return false;"
            ) {
                span(class:'checkbox-checked') {
                    mkp.yieldUnescaped("&nbsp;")
                }
                span(class:'activeFq') {
                    mkp.yieldUnescaped(message(code: fqLabel, default: fqLabel).replaceFirst(':',': '))
                }
            }
        }
    }

    /**
     * Generate facet links in the left hand column
     *
     * @attr fieldResult REQUIRED
     * @attr facetResult REQUIRED
     * @attr queryParam REQUIRED
     */
    def facetLinkItems = { attrs ->
        def fieldResult = attrs.fieldResult
        def facetResult = attrs.facetResult
        def queryParam = attrs.queryParam
        def mb = new MarkupBuilder(out)
        def fqValue = fieldResult.label?.encodeAsURL()
        def linkTitle = "Filter results by ${alatag.formatDynamicFacetName(fieldName:facetResult.fieldName)}"

        def addCounts = { count ->
            mb.span(class:"facetCount") {
                mkp.yieldUnescaped(" (")
                mkp.yield(g.formatNumber(number: "${count}", format:"#,###,###"))
                mkp.yieldUnescaped(")")
            }
        }

        // Catch specific facets fields
        if (fieldResult.fq) {
            // biocache-service has provided a fq field in the fieldResults list
            mb.li {
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
        } else if (StringUtils.startsWith(facetResult.fieldName, "occurrence_")) {
            // decade year ranges
            def startDate = ""
            def startYear = ""
            def endDate = ""
            def endYear = ""

            if (fieldResult.label.toLowerCase() == "before") {
                startDate = "*"
                startYear = "Before "
                endDate = facetResult.fieldResult?.get(0)?.label
                endYear = endDate?.substring(0, 4)
            } else {
                startDate = fieldResult.label
                startYear = fieldResult.label.substring(0, 4)
                endDate = fieldResult.label.replace('0-01-01T00:00:00Z','9-12-31T11:59:59Z')
                endYear = " - " + endDate.substring(0, 4)
            }

            mb.li {
                a(      href:"?${queryParam}&fq=${facetResult.fieldName}:[${startDate} TO ${endDate}]",
                        class: "tooltips",
                        title: linkTitle
                ) {
                    span(class:"checkbox-unchecked"){
                        mkp.yieldUnescaped("&nbsp;")
                    }
                    span(class:"facet-item") {
                        mkp.yieldUnescaped("${startYear} ${endYear}")
                        addCounts(fieldResult.count)
                    }
                }

            }
        } else {
            def label = g.message(code:"${facetResult.fieldName}.${fieldResult.label}", default:"")?:
                    g.message(code:"${fieldResult.label?:'unknown'}", default:"${fieldResult.label}")
            mb.li {
                a(      href:"?${queryParam}&fq=${facetResult.fieldName}:%22${fqValue}%22",
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
//        <c:forEach items="${groupedAssertions}" var="assertion">
//            <li id="${assertion.usersAssertionUuid}">
//                <fmt:message key="${assertion.name}"/>
//                <c:choose>
//                    <c:when test="${assertion.assertionByUser}">
//                        <br/>
//                        <strong>
//                            ( added by you
//                            <c:choose>
//                                <c:when test="${fn:length(assertion.users)>1}">
//                                    and ${fn:length(assertion.users) - 1} ${fn:length(assertion.users)>2 ? 'other users' : 'other user'})
//                                </c:when>
//                                <c:otherwise>
//                                 )
//                                </c:otherwise>
//                            </c:choose>
//                        </strong>
//                    </c:when>
//                    <c:otherwise>
//                        (added by ${fn:length(assertion.users)} ${fn:length(assertion.users)>1 ? 'users' : 'user'})
//                    </c:otherwise>
//                </c:choose>
//            </li>
//        </c:forEach>
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

    def loggedInUserId = { attrs ->
        out << authService?.getUserId()
    }

    def outageBanner = { attrs ->
        out << "TODO "
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
        def skin = grailsApplication.config.ala.skin?.toUpperCase()
        def sources = webServicesService.getLoggerSources()
        sources.each {
            if (it.name == skin) {
                out << it.id
            }
        }
    }

}

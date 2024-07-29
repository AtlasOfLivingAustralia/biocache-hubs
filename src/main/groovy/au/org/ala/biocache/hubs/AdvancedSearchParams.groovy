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

import grails.validation.Validateable
import groovy.util.logging.Slf4j
import org.apache.commons.httpclient.URIException
import org.apache.commons.httpclient.util.URIUtil
import org.apache.commons.lang3.StringUtils
import org.apache.commons.text.StringTokenizer
import org.apache.commons.text.matcher.StringMatcher
import org.apache.commons.text.matcher.StringMatcherFactory
import org.grails.web.util.WebUtils

/**
 * Request parameters for the advanced search form (form backing bean)
 *
 * @author "Nick dos Remedios <Nick.dosRemedios@csiro.au>"
 */
@Slf4j
class AdvancedSearchParams implements Validateable {
    String text = ""
    String taxa = ""
    String[] lsid = []  // deprecated
    String[] taxonText = []
    String nameType = ""
    String raw_taxon_name = ""
    String species_group = ""
    String institution_collection = ""
    String dataset = ""
    String state = ""
    String country = ""
    String ibra = ""
    String imcra = ""
    String imcra_meso = ""
    String places = ""
    String lga = ""
    String type_status = ""
    Boolean type_material = false
    String basis_of_record = ""
    String catalogue_number = ""
    String record_number = ""
    String collector = ""
    String collectors_number = ""
    String identified_by = ""
    String identified_date_start = ""
    String identified_date_end = ""
    String cultivation_status = ""
    String loan_destination = ""
    String duplicate_inst = ""
    String loan_identifier = ""
    String state_conservation = ""
    String start_date = ""
    String end_date = ""
    String last_load_start = ""
    String last_load_end = ""
    String seed_viability_start = ""
    String seed_viability_end = ""
    String seed_quantity_start = ""
    String seed_quantity_end = ""
    String start_year = ""
    String end_year = ""
    String collector_text = ""
    String habitat = ""

    private final String QUOTE = "\""
    private final String BOOL_OP = "AND"

    /**
     * This custom toString method outputs a valid /occurrence/search query string.
     *
     * @return q
     */
    @Override
    public String toString() {
        List queryItems = []
        // build up q from the simple fields first...
        if (text) queryItems.add("text:" + quoteText(text))
        if (raw_taxon_name) queryItems.add("raw_name:" + quoteText(raw_taxon_name))
        if (species_group) queryItems.add("species_group:" + species_group)
        if (state) queryItems.add("state:" + quoteText(state))
        if (country) queryItems.add("country:" + quoteText(country))
        if (ibra) queryItems.add("cl1048:" + quoteText(ibra))
        if (imcra) queryItems.add("cl21:" + quoteText(imcra))
        if (imcra_meso) queryItems.add("cl966:" + quoteText(imcra_meso))
        if (lga) queryItems.add("cl959:" + quoteText(lga))
        if (places) queryItems.add("places:" + quoteText(places.trim()))
        if (type_status) queryItems.add("type_status:" + type_status)
        if (dataset) queryItems.add("data_resource_uid:" + dataset)
        if (type_material) queryItems.add("type_status:" + "*")
        if (basis_of_record) queryItems.add("basis_of_record:" + basis_of_record)
        if (catalogue_number) queryItems.add("catalogue_number:" + quoteText(catalogue_number))
        if (record_number) queryItems.add("record_number:" + quoteText(record_number))
        if (cultivation_status) queryItems.add("establishment_means:" + quoteText(cultivation_status))
        if (collector) queryItems.add("collector_text:" + quoteText(collector))
        if (identified_by) queryItems.add("identified_by_text:" + quoteText(identified_by))
        if (loan_destination) queryItems.add("loan_destination:" + loan_destination)
        if (loan_identifier) queryItems.add("loan_identifier:" + loan_identifier)
        if (duplicate_inst) queryItems.add("duplicate_inst:" + duplicate_inst)
        if (state_conservation) queryItems.add("state_conservation:" + state_conservation)
        if (collector_text) queryItems.add("collector_text:" + collector_text)
        if (habitat) queryItems.add("habitat:" + habitat)
        //if (collectors_number) queryItems.add("collector:" + collectors_number); // TODO field in SOLR not active

        ArrayList<String> lsids = new ArrayList<String>()
        ArrayList<String> taxas = new ArrayList<String>()

        taxonText.each { tt ->
            if (tt) {
                taxas.add("\"" + tt.trim() + "\"")
            }
        }

        if (taxas) {
            log.debug "taxas = ${taxas} || nameType = ${nameType}"
            taxa = StringUtils.join(taxas.collect {nameType + ":" + it}, " OR ")
            if (taxas.size() > 1) { // if more than one taxa query, add braces so we get correct Boolean precedence
                taxa = "(" + taxa + ")"
            }
            queryItems.add(taxa)
        }

        // TODO: deprecate this code (?)
        if (lsids) {
            queryItems.add("lsid:" + StringUtils.join(lsids, " OR lsid:"))
        }

        if (institution_collection) {
            String label = (StringUtils.startsWith(institution_collection, "in")) ? "institution_uid" : "collection_uid"
            queryItems.add(label + ":" + institution_collection)
        }

        if (start_date || end_date) {
            String value = combineDates(start_date, end_date)
            queryItems.add("occurrence_date:" + value)
        }

        if (last_load_start || last_load_end) {
            String value = combineDates(last_load_start, last_load_end)
            queryItems.add("modified_date:" + value)
        }

        if (identified_date_start || identified_date_end) {
            String value = combineDates(identified_date_start, identified_date_end)
            queryItems.add("identified_date:" + value)
        }

        if (seed_viability_start || seed_viability_end) {
            String start = (!seed_viability_start) ? "*" : seed_viability_start
            String end = (!seed_viability_end) ? "*" : seed_viability_end
            String value = "[" + start + " TO " + end + "]"
            queryItems.add("ViabilitySummary_d:" + value)
        }

        if (seed_quantity_start || seed_quantity_end) {
            String start = (!seed_quantity_start) ? "*" : seed_quantity_start
            String end = (!seed_quantity_end) ? "*" : seed_quantity_end
            String value = "[" + start + " TO " + end + "]"
            queryItems.add("AdjustedSeedQuantity_i:" + value)
        }

        if (start_year || end_year) {
            String start = (!start_year) ? "*" : start_year
            String end = (!end_year) ? "*" : end_year
            String value = "[" + start + " TO " + end + "]"
            queryItems.add("year:" + value)
        }

        String encodedQ = queryItems.join(" ${BOOL_OP} ").toString().trim()

        try {
            // attempt to do query encoding
            encodedQ = URIUtil.encodeWithinQuery(encodedQ.replaceFirst("\\?", ""))
        } catch (URIException ex) {
            log.error("URIUtil error: " + ex.getMessage(), ex)
        }

        String finalQuery = ((encodedQ) ? "q=" + encodedQ : "")
        log.debug("query: " + finalQuery)

        return finalQuery
    }

    /**
     * Advanced search field "ALL of these words (full text)" assumes default Boolean operator will be AND
     * but bugs happen and someone changed it to be OR. So we explicitly combine terms with AND to work-around
     * this bug. Can be used with any SOLR field.
     *
     * @param field (optional)
     * @param text
     * @return
     */
    String combineTermsWithAND(String field, String text) {
        // StringTokenizer code taken from https://stackoverflow.com/a/49845863/249327
        StringTokenizer st = new StringTokenizer( text )
        StringMatcher sm = StringMatcherFactory.INSTANCE.quoteMatcher()
        st.setQuoteMatcher( sm )
        List termsList = st.tokenList
        List formattedTermsList = []
        String fieldPrefix = field ? "${field}:" : ""

        termsList.each {
            String term = StringUtils.containsWhitespace(it) ? quoteText(it) : it
            formattedTermsList.add("${fieldPrefix}${term}")
        }

        formattedTermsList.join(" AND ")
    }

    /**
     * Get the queryString in the form of a Map - for use with 'params' attribute
     * in redirect, etc.
     *
     * @return
     */
    public Map toParamMap() {
        WebUtils.fromQueryString(toString())
    }

    /**
     * Strip unwanted characters from input string
     *
     * @param withCharsToStrip
     * @return
     */
    private String stripChars(String withCharsToStrip){
        if(withCharsToStrip!=null){
            return withCharsToStrip.replaceAll("\\.","")
        }
        return null
    }

    /**
     * Combine two dates [YYYY-MM-DD] into a SOLR date range String
     *
     * @param startDate
     * @param endDate
     * @return
     */
    private String combineDates(String startDate, String endDate) {
        log.info("dates check: " + startDate + "|" + endDate)
        String value = ""
        // TODO check input dates are valid
        if (startDate) {
            value = "[" + startDate + "T00:00:00Z TO "
        } else {
            value = "[* TO "
        }
        if (endDate) {
            value = value + endDate + "T00:00:00Z]"
        } else {
            value = value + "*]"
        }
        return value
    }

    /**
     * Surround phrase search with quotes
     *
     * @param text
     * @return
     */
    private String quoteText(String text) {
        if (StringUtils.contains(text, " ")) {
            text = QUOTE + text + QUOTE
        }

        return text
    }

}

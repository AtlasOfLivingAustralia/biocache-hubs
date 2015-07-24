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
import groovy.util.logging.Log4j
import org.apache.commons.httpclient.URIException
import org.apache.commons.httpclient.util.URIUtil
import org.apache.commons.lang.StringUtils
import org.codehaus.groovy.grails.web.util.WebUtils

/**
 * Request parameters for the advanced search form (form backing bean)
 *
 * @author "Nick dos Remedios <Nick.dosRemedios@csiro.au>"
 */
@Validateable
@Log4j
class AdvancedSearchParams {
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

    private final String QUOTE = "\""

    /**
     * This custom toString method outputs a valid SOLR query (q param value).
     *
     * @return q
     */
    @Override
    public String toString() {
        StringBuilder q = new StringBuilder()
        // build up q from the simple fields first...
        if (text) q.append("text:").append(text)
        if (raw_taxon_name) q.append(" raw_name:").append(quoteText(raw_taxon_name))
        if (species_group) q.append(" species_group:").append(species_group)
        if (state) q.append(" state:").append(quoteText(state))
        if (country) q.append(" country:").append(quoteText(country))
        if (ibra) q.append(" cl1048:").append(quoteText(ibra))
        if (imcra) q.append(" cl21:").append(quoteText(imcra))
        if (imcra_meso) q.append(" cl966:").append(quoteText(imcra_meso))
        if (lga) q.append(" cl959:").append(quoteText(lga))
        if (places) q.append(" places:").append(quoteText(places.trim()))
        if (type_status) q.append(" type_status:").append(type_status)
        if (dataset) q.append(" data_resource_uid:").append(dataset)
        if (type_material) q.append(" type_status:").append("*")
        if (basis_of_record) q.append(" basis_of_record:").append(basis_of_record)
        if (catalogue_number) q.append(" catalogue_number:").append(quoteText(catalogue_number))
        if (record_number) q.append(" record_number:").append(quoteText(record_number))
        if (cultivation_status) q.append(" establishment_means:").append(quoteText(cultivation_status))
        if (collector) q.append(" collector_text:").append(quoteText(collector))
        if (identified_by) q.append(" identified_by_text:").append(quoteText(identified_by))
        if (loan_destination) q.append(" loan_destination:").append(loan_destination)
        if (loan_identifier) q.append(" loan_identifier:").append(loan_identifier)
        if (duplicate_inst) q.append(" duplicate_inst:").append(duplicate_inst)
        if (state_conservation) q.append(" state_conservation:").append(state_conservation)
        //if (collectors_number) q.append(" collector:").append(collectors_number); // TODO field in SOLR not active

        ArrayList<String> lsids = new ArrayList<String>()
        ArrayList<String> taxas = new ArrayList<String>()

        // iterate over the taxa search inputs and if lsid is set use it otherwise use taxa input
        taxonText.each { tt ->
            if (tt) {
                taxas.add(stripChars(quoteText(tt)));
            }
        }

        // if more than one taxa query, add braces so we get correct Boolean precedence
        String[] braces = ["",""]
        if (taxas.size() > 1) {
            braces[0] = "("
            braces[1] = ")"
        }

        if (taxas) {
            log.debug "taxas = ${taxas} || nameType = ${nameType}"
            // build up OR'ed taxa query with braces if more than one taxon
            q.append(" ").append(braces[0]).append(nameType).append(":")
            q.append(StringUtils.join(taxas, " OR " + nameType + ":")).append(braces[1])
            log.debug "q = ${q}"
        }

        // TODO: deprecate this code (?)
        if (lsids) {
            q.append(" lsid:").append(StringUtils.join(lsids, " OR lsid:"))
        }

        if (institution_collection) {
            String label = (StringUtils.startsWith(institution_collection, "in")) ? " institution_uid" : " collection_uid"
            q.append(label).append(":").append(institution_collection)
        }

        if (start_date || end_date) {
            String value = combineDates(start_date, end_date)
            q.append(" occurrence_date:").append(value)
        }

        if (last_load_start || last_load_end) {
            String value = combineDates(last_load_start, last_load_end)
            q.append(" modified_date:").append(value)
        }

        if (identified_date_start || identified_date_end) {
            String value = combineDates(identified_date_start, identified_date_end)
            q.append(" identified_date:").append(value)
        }

        if (seed_viability_start || seed_viability_end) {
            String start = (!seed_viability_start) ? "*" : seed_viability_start
            String end = (!seed_viability_end) ? "*" : seed_viability_end
            String value = "[" + start + " TO " + end + "]"
            q.append(" ViabilitySummary_d:").append(value)
        }

        if (seed_quantity_start || seed_quantity_end) {
            String start = (!seed_quantity_start) ? "*" : seed_quantity_start
            String end = (!seed_quantity_end) ? "*" : seed_quantity_end
            String value = "[" + start + " TO " + end + "]"
            q.append(" AdjustedSeedQuantity_i:").append(value)
        }

        if (start_year || end_year) {
            String start = (!start_year) ? "*" : start_year
            String end = (!end_year) ? "*" : end_year
            String value = "[" + start + " TO " + end + "]"
            q.append(" year:").append(value)
        }

        String finalQuery = ""

        if (taxa) {
            String query = URLEncoder.encode(q.toString().replace("?", ""))
            finalQuery = "taxa=" + taxa + "&q=" + query
        } else {
            try {
                finalQuery = "q=" + URIUtil.encodeWithinQuery(q.toString().trim()); //URLEncoder.encode(q.toString().trim()); // TODO: use non-deprecated version with UTF-8
            } catch (URIException ex) {
                log.error("URIUtil error: " + ex.getMessage(), ex)
                finalQuery = "q=" + q.toString().trim(); // fall back
            }
        }
        log.debug("query: " + finalQuery)
        return finalQuery
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

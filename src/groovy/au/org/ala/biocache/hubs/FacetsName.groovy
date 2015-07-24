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

import groovy.util.logging.Log4j

/**
 * Enum for facet fields needed to populate drop-down lists in advanced search page, etc.
 * Now deprecated for a config var: facets.cached (list of facet fields)
 *
 * @author "Nick dos Remedios <Nick.dosRemedios@csiro.au>"
 */
@Log4j
@Deprecated
enum FacetsName {
    COLLECTION("collection_uid"),
    INSTITUTION("institution_uid"),
    DATA_RESOURCE("data_resource_uid"),
    DATA_PROVIDER("data_provider_uid"),
    TYPE_STATUS("type_status"),
    BASIS_OF_RECORD("basis_of_record"),
    SPECIES_GROUP("species_group"),
    LOAD_DESTINATION("loan_destination"),
    CULTIVATION_STATUS("establishment_means"),
    STATE_CONSERVATION("state_conservation"),
    STATES("state"),
    IBRA("ibra"),
    IMCRA("imcra"),
    IMCRA_MESO("cl966"),
    COUNTRIES("country"),
    LGA("cl959")

    String fieldname

    FacetsName(String name) {
        this.fieldname = name
    }

    /**
     * Do a lookup on the fieldName field
     *
     * @param fieldName
     * @return
     */
    public static FacetsName valueOfFieldName(String fieldName) {
        for (FacetsName v : values()) {
            if (v.fieldname.equals(fieldName)) {
                log.info "matched value = ${v}"
                return v;
            }
        }
        throw new IllegalArgumentException(
                "No enum const " + FacetsName.class + "@fieldName." + fieldName);
    }
}
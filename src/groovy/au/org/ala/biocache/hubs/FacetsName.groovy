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

/**
 * Enum for facet fields needed to populate drop-down lists in advanced search page, etc.
 *
 * @author "Nick dos Remedios <Nick.dosRemedios@csiro.au>"
 */
enum FacetsName {
    COLLECTION("collection_uid"),
    INSTITUTION("institution_uid"),
    DATA_RESOURCE("data_resource_uid"),
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
}
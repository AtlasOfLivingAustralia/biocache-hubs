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
 * Service to cache the facet values available from a given data hub.
 * Used to populate the values in select drop-down lists in advanced search page.
 */
class DoiService {
    def webServicesService

    /**
     * Get the facets values (and labels if available) for the requested facet field.
     *
     * @param facet
     * @return
     */
    List getDoiInfo(record) {
        List doiInfo = []
        if (record.referencedPublications){
            record.referencedPublications.each { referencedPublication ->
                Map doiInfoMap = webServicesService.getDoiInfo(referencedPublication.identifier)
                doiInfoMap['annotation'] = referencedPublication
                doiInfo << doiInfoMap
            }
        }
        doiInfo
    }
}

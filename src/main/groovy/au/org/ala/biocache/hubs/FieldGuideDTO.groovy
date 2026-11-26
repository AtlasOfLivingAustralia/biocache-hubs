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

import grails.converters.JSON

/**
 * Field Guide DTO
 *
 * @author "Nick dos Remedios <Nick.dosRemedios@csiro.au>"
 */
class FieldGuideDTO {
    def guids = []
    def title = ""
    def link = ""

    String getJson() {

        def jsonObj = getMap() as JSON
        return jsonObj.toString()
    }

    Map<String, Object> getMap() {

        return [
                guids: guids,
                title: title,
                link: link
        ]
    }

    @Override
    String toString() {
        return "FieldGuideDTO{" +
                "guids=" + guids +
                ", title=" + title +
                ", link=" + link +
                '}';
    }
}

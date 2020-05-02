/*
 * Copyright (C) 2018 Atlas of Living Australia
 * All Rights Reserved.
 * The contents of this file are subject to the Mozilla Public
 * License Version 1.1 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of
 * the License at http://www.mozilla.org/MPL/
 * Software distributed under the License is distributed on an "AS
 * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * rights and limitations under the License.
 */

package au.org.ala.biocache.hubs

import grails.test.mixin.TestFor
import spock.lang.Specification

/**
 * Unit tests for {@link au.org.ala.biocache.hubs.OccurrenceController}
 *
 * @author "Nick dos Remedios <Nick.dosRemedios@csiro.au>"
 */
@TestFor(OccurrenceController)
class OccurrenceControllerSpec extends Specification {

    void "test getListOfLayerIds once"() {
        given:
            def q = "cl10955:*"
            def ssrp = new SpatialSearchRequestParams(q:q)
        when:
            def list = controller.getListOfLayerIds(ssrp)
        then:
            list == ["cl10955"]
    }

    void "test getListOfLayerIds via data table"() {
        expect:
        controller.getListOfLayerIds(new SpatialSearchRequestParams(q:q, fq:fq)) == ids

        where:
        q           | fq                    | ids
        "cl10955:*" | []                    | ["cl10955"]
        "cl10955:*" | ["el123:foo"]         | ["cl10955","el123"]
        "element"   | ["cl10955:*"]         | ["cl10955"]
        "el123a:*"  | ["el1234:*"]          | ["el1234"]
        ""          | ["dl1234:*"]          | []
        ""          | ["-cl1234:*"]         | ["cl1234"]
        "dl1234:*"  | []                    | []
        "dl1234:*"  | ["cl456:[* TO *]"]    | ["cl456"]
        "*:*"       | ["el123:*","cl456:*"] | ["el123","cl456"]
    }
}

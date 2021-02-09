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

import au.org.ala.dataquality.model.QualityCategory
import au.org.ala.dataquality.model.QualityFilter
import grails.test.mixin.TestFor
import grails.util.Holders
import spock.lang.Specification
import spock.lang.Unroll

/**
 * Unit tests for {@link au.org.ala.biocache.hubs.OccurrenceTagLib}
 *
 * @author "Nick dos Remedios <Nick.dosRemedios@csiro.au>"
 */
@TestFor(OccurrenceTagLib)
class OccurrenceTagLibSpec extends Specification {

    def setup() {
        Holders.grailsApplication.config.dataResourceUuid.alaSightings = "dr364"
        Holders.grailsApplication.config.dataResourceUuid.iNaturalist = "dr1411"
        Holders.grailsApplication.config.dataResourceUuid.flickr = "dr360"
    }

    static doWithConfig(config) {
        config.dataquality.enabled = 'true'
    }

    void "test sanitizeBodyText plain text"() {
        given:
            def text = "Australian Plant Image Index (APII)"
        when:
            def html = tagLib.sanitizeBodyText(text)
        then:
            html == text
    }

    void "test sanitizeBodyText LSID text"() {
        given:
            def text = "urn:lsid:biocol.org:col:34978"
        when:
            def html = tagLib.sanitizeBodyText(text)
        then:
            html == text
    }

    void "test sanitizeBodyText suspect text"() {
        given:
            def text = "Australian Plant Image Index (APII) <img src='https://www.ala.org.au/commonui-bs3/img/ala-logo-2016-inline'>"
        when:
            def html = tagLib.sanitizeBodyText(text)
        then:
            html == "Australian Plant Image Index (APII) "
    }

    void "test sanitizeBodyText html no target attr"() {
        // taken from record ID c31644ae-cb2b-4111-9966-afa8cac42f01
        given:
            def text = "Taken at Loughnan Nature Reserve NSW, Australian Plant Image Index (<a href='http://www.anbg.gov.au/photo/image-collection.html'>APII</a>) Photo: <a href='www.anbg.gov.au/photo/apii/id/dig/1975'>dig1975</a>"
        when:
            def html = tagLib.sanitizeBodyText(text, false)
        then:
            html == "Taken at Loughnan Nature Reserve NSW, Australian Plant Image Index (<a href=\"http://www.anbg.gov.au/photo/image-collection.html\" rel=\"nofollow\">APII</a>) Photo: dig1975"
    }

    void "test sanitizeBodyText html text"() {
        // taken from record ID c31644ae-cb2b-4111-9966-afa8cac42f01
        given:
            def text = "Taken at Loughnan Nature Reserve NSW, Australian Plant Image Index (<a href='http://www.anbg.gov.au/photo/image-collection.html'>APII</a>) Photo: <a href='www.anbg.gov.au/photo/apii/id/dig/1975'>dig1975</a>"
        when:
            def html = tagLib.sanitizeBodyText(text)
        then:
            html == "Taken at Loughnan Nature Reserve NSW, Australian Plant Image Index (<a target=\"_blank\" href=\"http://www.anbg.gov.au/photo/image-collection.html\" rel=\"nofollow\">APII</a>) Photo: dig1975"
    }


    void "test sanitizeBodyText ALA generated html text"() {
        // taken from record ID df9c78e6-6908-4ae4-8b72-09b22ef9c9ff
        given:
            def text = "<a href=https://biocache.ala.org.au/occurrences/search?q=institution_code:NMV%20AND%20collection_code:Ichthyology%20AND%20catalogue_number:A30460-29>source specimen NMV:Ichthyology:A30460-29</a>"
        when:
            def html = tagLib.sanitizeBodyText(text)
        then:
            html == "<a target=\"_blank\" href=\"https://biocache.ala.org.au/occurrences/search?q&#61;institution_code:NMV%20AND%20collection_code:Ichthyology%20AND%20catalogue_number:A30460-29\" rel=\"nofollow\">source specimen NMV:Ichthyology:A30460-29</a>"
    }

    void "test sanitizeBodyText ALA generated html text 2"() {
        // taken from record ID df9c78e6-6908-4ae4-8b72-09b22ef9c9ff
        given:
            def text = "Collectors were identical <br> Occurrence was compared without day <br> Coordinates were identical <br>"
        when:
            def html = tagLib.sanitizeBodyText(text)
        then:
            html == "Collectors were identical <br /> Occurrence was compared without day <br /> Coordinates were identical <br />"
    }

    void "test sanitizeBodyText ALA generated html text 3"() {
        // taken from record ID df9c78e6-6908-4ae4-8b72-09b22ef9c9ff
        given:
            def text = "<a href=\"https://collections.ala.org.au/public/show/in16\"> Museums Victoria </a> <br/> <span class=\"originalValue\">Supplied institution code \"NMV\"</span>"
        when:
            def html = tagLib.sanitizeBodyText(text)
        then:
            html == "<a target=\"_blank\" href=\"https://collections.ala.org.au/public/show/in16\" rel=\"nofollow\"> Museums Victoria </a> <br /> <span class=\"originalValue\">Supplied institution code &#34;NMV&#34;</span>"
    }

    void "test sanitizeBodyText for taxa search span from biocache-service"() {
        // taken from acacia search - https://biocache-ws.ala.org.au/ws/occurrences/search?q=taxa:acacia
        given:
        def text = "<span class='lsid' id='http://id.biodiversity.org.au/node/apni/6719673'>GENUS: Acacia</span>"
        when:
        def html = tagLib.sanitizeBodyText(text)
        then:
        html == "<span class=\"lsid\" id=\"http://id.biodiversity.org.au/node/apni/6719673\">GENUS: Acacia</span>"
    }

    void "test sanitizeBodyText XSS test 1"() {
        // for issue AtlasOfLivingAustralia/biocache-hubs/issues/327
        // <svg/onload=alert(123)>
        given:
        def text = "<svg/onload=alert(123)>"
        when:
        def html = tagLib.sanitizeBodyText(text)
        then:
        html == ""
    }

    void "test sanitizeBodyText HTML test 4"() {
        // div
        given:
        def text = "<div>acacia</div>"
        when:
        def html = tagLib.sanitizeBodyText(text)
        then:
        html == "acacia"
    }

    void "test Biocollect sightings user link via getLinkForUserId() tag"() {
        // taken from record ID 04eacba3-cec1-4d6b-8822-78444655081d
        given:
            grailsApplication.config.sightings.baseUrl = "https://sightings.ala.org.au"
        when:
            def html = tagLib.getLinkForUserId(userName:"David Sando", userId: "1267", dataResourceUid: "dr364")
        then:
            html == "<a href=\"https://sightings.ala.org.au/spotter/1267\">David Sando</a>"

    }

    void "test iNaturalist user page link via getLinkForUserId() tag"() {
        // taken from record ID 94f19c5b-1065-4ac1-9b77-2abf4c2bcbc4
        given:
            grailsApplication.config.iNaturalist.baseUrl = "https://inaturlist.ala.org.au"
        when:
            def html = tagLib.getLinkForUserId(userName:"peggydnew", dataResourceUid: "dr1411")
        then:
            html == "<a href=\"https://inaturlist.ala.org.au/people/peggydnew\">peggydnew</a>"
    }

    void "test Flickr user page link via getLinkForUserId() tag"() {
        // taken from record ID 674aa318-8f9a-4218-a43f-6c47f0070c82
        when:
            def html = tagLib.getLinkForUserId(userName:"Donald Hobern", dataResourceUid: "dr360", occurrenceId: "https://www.flickr.com/photos/dhobern/5466675452/")
        then:
            html == "<a href=\"https://www.flickr.com/photos/dhobern\">Donald Hobern</a>"
    }

    @Unroll
    void 'test linkQualityCategory enable: #enable expand #expand'(boolean enable, boolean expand, Map searchParams, String result) {
        given:
        QualityCategory category = new QualityCategory(name: 'asdf', label: 'asdf', qualityFilters: [new QualityFilter(filter: 'a:b', enabled: true), new QualityFilter(filter: 'c:d', enabled: true), new QualityFilter(filter: 'e:f', enabled: false)])
        params.q = '*:*'
        params.putAll(searchParams)

        when:
        def html = applyTemplate('<alatag:linkQualityCategory class="tooltips" title="asdf" controller="occurrence" action="search" category="${category}" enable="${' + enable + '}" expand="${' + expand + '}">FOO</alatag:linkQualityCategory>', [category: category])

        then:
        html == result

        where:
        enable || expand || searchParams || result
        true    | true    | [fq: ['a:z', 'c:d'], disableQualityFilter: ['qwerty', 'asdf']] | '<a href="/occurrence/search?q=*%3A*&amp;fq=a%3Az&amp;disableQualityFilter=qwerty" class="tooltips" title="asdf">FOO</a>'
        true    | false   | [fq: ['a:z', 'c:d'], disableQualityFilter: ['qwerty', 'asdf']] | '<a href="/occurrence/search?q=*%3A*&amp;fq=a%3Az&amp;fq=c%3Ad&amp;disableQualityFilter=qwerty" class="tooltips" title="asdf">FOO</a>'
        false   | true    | [fq: ['x:y', 'y:z'], disableQualityFilter: ['qwerty']] | '<a href="/occurrence/search?q=*%3A*&amp;fq=x%3Ay&amp;fq=y%3Az&amp;fq=a%3Ab&amp;fq=c%3Ad&amp;disableQualityFilter=qwerty&amp;disableQualityFilter=asdf" class="tooltips" title="asdf">FOO</a>'
        false   | false   | [fq: ['x:y', 'y:z'], disableQualityFilter: 'qwerty'] | '<a href="/occurrence/search?q=*%3A*&amp;fq=x%3Ay&amp;fq=y%3Az&amp;disableQualityFilter=qwerty&amp;disableQualityFilter=asdf" class="tooltips" title="asdf">FOO</a>'
    }
}

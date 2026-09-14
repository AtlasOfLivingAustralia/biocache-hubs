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
import grails.config.Config
import grails.testing.web.taglib.TagLibUnitTest
import grails.util.Holders
import spock.lang.Ignore
import spock.lang.Specification
import spock.lang.Unroll

/**
 * Unit tests for {@link au.org.ala.biocache.hubs.OccurrenceTagLib}
 *
 * @author "Nick dos Remedios <Nick.dosRemedios@csiro.au>"
 */
class OccurrenceTagLibSpec extends Specification implements TagLibUnitTest<OccurrenceTagLib> {
    @Override
    Closure doWithConfig() {{ Config config ->
        config.dataquality.enabled = true
        config.dataResourceUuid.alaSightings = "dr364"
        config.dataResourceUuid.iNaturalist = "dr1411"
        config.dataResourceUuid.flickr = "dr360"
        config.license.lookup = [
            [pattern: '^CC0$', label: 'CC0', img: 'https://licensebuttons.net/p/zero/1.0/88x31.png', url: 'https://creativecommons.org/publicdomain/zero/1.0/'],
            [pattern: '^PDM$', label: 'Public Domain Mark', img: 'https://licensebuttons.net/p/mark/1.0/88x31.png', url: 'https://creativecommons.org/publicdomain/mark/1.0/'],
            [pattern: '.*', label: '', img: '', url: '']
        ]
    }}

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
            def html = tagLib.getLinkForUserId(userName:"peggydnew", userId: "peggydnew", dataResourceUid: "dr1411")
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

    @Unroll
    void 'test parseCcByLicense recognises "#license"'(String license, String label, String img, String url) {
        when:
        def entry = tagLib.parseCcByLicense(license)

        then:
        entry.label == label
        entry.img == img
        entry.url == url

        where:
        license                    || label            | img                                                              | url
        'CC-BY'                    || 'CC BY'          | 'https://licensebuttons.net/l/by/4.0/88x31.png'                 | 'https://creativecommons.org/licenses/by/4.0/'
        'cc-by'                    || 'CC BY'          | 'https://licensebuttons.net/l/by/4.0/88x31.png'                 | 'https://creativecommons.org/licenses/by/4.0/'
        'CC-BY 3.0 (Au)'           || 'CC BY'          | 'https://licensebuttons.net/l/by/3.0/au/88x31.png'              | 'https://creativecommons.org/licenses/by/3.0/au/'
        'CC-BY 3.0 (Int)'          || 'CC BY'          | 'https://licensebuttons.net/l/by/3.0/88x31.png'                 | 'https://creativecommons.org/licenses/by/3.0/'
        'CC-BY 3.0 (NZ)'           || 'CC BY'          | 'https://licensebuttons.net/l/by/3.0/nz/88x31.png'              | 'https://creativecommons.org/licenses/by/3.0/nz/'
        'CC-BY 4.0 (Au)'           || 'CC BY'          | 'https://licensebuttons.net/l/by/4.0/88x31.png'                 | 'https://creativecommons.org/licenses/by/4.0/'
        'CC-BY 4.0 (Int)'          || 'CC BY'          | 'https://licensebuttons.net/l/by/4.0/88x31.png'                 | 'https://creativecommons.org/licenses/by/4.0/'
        'CC-BY-Aus'                || 'CC BY'          | 'https://licensebuttons.net/l/by/3.0/au/88x31.png'              | 'https://creativecommons.org/licenses/by/3.0/au/'
        'CC-BY-Int'                || 'CC BY'          | 'https://licensebuttons.net/l/by/4.0/88x31.png'                 | 'https://creativecommons.org/licenses/by/4.0/'
        'CC-BY-NC 2.5 (Int)'       || 'CC BY-NC'       | 'https://licensebuttons.net/l/by-nc/2.5/88x31.png'              | 'https://creativecommons.org/licenses/by-nc/2.5/'
        'CC-BY-NC 3.0 (Au)'        || 'CC BY-NC'       | 'https://licensebuttons.net/l/by-nc/3.0/au/88x31.png'           | 'https://creativecommons.org/licenses/by-nc/3.0/au/'
        'CC-BY-NC 3.0 (Aus)'       || 'CC BY-NC'       | 'https://licensebuttons.net/l/by-nc/3.0/au/88x31.png'           | 'https://creativecommons.org/licenses/by-nc/3.0/au/'
        'CC-BY-NC 3.0 (Int)'       || 'CC BY-NC'       | 'https://licensebuttons.net/l/by-nc/3.0/88x31.png'              | 'https://creativecommons.org/licenses/by-nc/3.0/'
        'CC-BY-NC 4.0 (Int)'       || 'CC BY-NC'       | 'https://licensebuttons.net/l/by-nc/4.0/88x31.png'              | 'https://creativecommons.org/licenses/by-nc/4.0/'
        'CC-BY-NC-Aus'             || 'CC BY-NC'       | 'https://licensebuttons.net/l/by-nc/3.0/au/88x31.png'           | 'https://creativecommons.org/licenses/by-nc/3.0/au/'
        'CC-BY-NC-Int'             || 'CC BY-NC'       | 'https://licensebuttons.net/l/by-nc/4.0/88x31.png'              | 'https://creativecommons.org/licenses/by-nc/4.0/'
        'CC-BY-NC-ND 4.0 (Int)'    || 'CC BY-NC-ND'    | 'https://licensebuttons.net/l/by-nc-nd/4.0/88x31.png'           | 'https://creativecommons.org/licenses/by-nc-nd/4.0/'
        'CC-BY-NC-SA 4.0 (Int)'    || 'CC BY-NC-SA'    | 'https://licensebuttons.net/l/by-nc-sa/4.0/88x31.png'           | 'https://creativecommons.org/licenses/by-nc-sa/4.0/'
        'CC-BY-NC'                 || 'CC BY-NC'       | 'https://licensebuttons.net/l/by-nc/4.0/88x31.png'              | 'https://creativecommons.org/licenses/by-nc/4.0/'
        'CC-BY-ND 4.0 (Int)'       || 'CC BY-ND'       | 'https://licensebuttons.net/l/by-nd/4.0/88x31.png'              | 'https://creativecommons.org/licenses/by-nd/4.0/'
        'CC-BY-SA 3.0 (Int)'       || 'CC BY-SA'       | 'https://licensebuttons.net/l/by-sa/3.0/88x31.png'              | 'https://creativecommons.org/licenses/by-sa/3.0/'
        'CC-BY-SA 4.0 (Int)'       || 'CC BY-SA'       | 'https://licensebuttons.net/l/by-sa/4.0/88x31.png'              | 'https://creativecommons.org/licenses/by-sa/4.0/'
    }

    @Unroll
    void 'test parseCcByLicense returns null for non CC-BY value "#license"'(String license) {
        expect:
        tagLib.parseCcByLicense(license) == null

        where:
        license << ['CC0', 'PDM', 'Custom', 'other', 'UNSPECIFIED', 'Creative Commons - license at record level', '']
    }

    @Unroll
    void 'test parseCcByLicense treats unrecognised 2-letter jurisdiction token "#license" as a country code'(String license, String img, String url) {
        when:
        def entry = tagLib.parseCcByLicense(license)

        then:
        entry.img == img
        entry.url == url

        where:
        license               || img                                                    | url
        'CC-BY 3.0 (US)'      || 'https://licensebuttons.net/l/by/3.0/us/88x31.png'    | 'https://creativecommons.org/licenses/by/3.0/us/'
        'CC-BY-NC 3.0 (JP)'   || 'https://licensebuttons.net/l/by-nc/3.0/jp/88x31.png' | 'https://creativecommons.org/licenses/by-nc/3.0/jp/'
    }

    void "test parseCcByLicense treats unrecognised multi-letter jurisdiction as international (no broken link)"() {
        when:
        def entry = tagLib.parseCcByLicense('CC-BY 3.0 (Wonderland)')

        then:
        entry.img == 'https://licensebuttons.net/l/by/3.0/88x31.png'
        entry.url == 'https://creativecommons.org/licenses/by/3.0/'
    }

    void "test parseCcByLicense jurisdiction aliases are configurable/extendable via license.ccBy.jurisdictions config"() {
        given:
        grailsApplication.config.license.ccBy.jurisdictions = [germany: 'de']

        when:
        def entry = tagLib.parseCcByLicense('CC-BY-NC-Germany')

        then:
        entry.img == 'https://licensebuttons.net/l/by-nc/3.0/de/88x31.png'
        entry.url == 'https://creativecommons.org/licenses/by-nc/3.0/de/'
    }

    void "test parseCcByLicense default/ported version are configurable via license.ccBy config"() {
        given:
        grailsApplication.config.license.ccBy.defaultVersion = '1.0'
        grailsApplication.config.license.ccBy.portedVersion = '2.0'

        expect:
        tagLib.parseCcByLicense('CC-BY').img == 'https://licensebuttons.net/l/by/1.0/88x31.png'
        tagLib.parseCcByLicense('CC-BY-Aus').img == 'https://licensebuttons.net/l/by/2.0/au/88x31.png'
    }

    void "test formatLicense renders CC0 badge from config lookup"() {
        when:
        def html = applyTemplate('<alatag:formatLicense license="CC0"/>')

        then:
        html == '<a href="https://creativecommons.org/publicdomain/zero/1.0/" target="_blank" rel="license"><img src="https://licensebuttons.net/p/zero/1.0/88x31.png" alt="CC0" /></a> CC0'
    }

    void "test formatLicense renders PDM badge from config lookup"() {
        when:
        def html = applyTemplate('<alatag:formatLicense license="PDM"/>')

        then:
        html == '<a href="https://creativecommons.org/publicdomain/mark/1.0/" target="_blank" rel="license"><img src="https://licensebuttons.net/p/mark/1.0/88x31.png" alt="PDM" /></a> PDM'
    }

    void "test formatLicense renders CC-BY badge via generic pattern matcher"() {
        when:
        def html = applyTemplate('<alatag:formatLicense license="CC-BY-NC-ND 4.0 (Int)"/>')

        then:
        html == '<a href="https://creativecommons.org/licenses/by-nc-nd/4.0/" target="_blank" rel="license"><img src="https://licensebuttons.net/l/by-nc-nd/4.0/88x31.png" alt="CC-BY-NC-ND 4.0 (Int)" /></a> CC-BY-NC-ND 4.0 (Int)'
    }

    void "test formatLicense allows license.lookup config to override the generic CC-BY pattern matcher"() {
        given:
        grailsApplication.config.license.lookup = [
            [pattern: '^CC-BY-NC 3\\.0 \\(Aus\\)$', label: 'Overridden', img: 'https://example.org/custom.png', url: 'https://example.org/custom-legal-code'],
            *grailsApplication.config.license.lookup
        ]

        when:
        def html = applyTemplate('<alatag:formatLicense license="CC-BY-NC 3.0 (Aus)"/>')

        then:
        html == '<a href="https://example.org/custom-legal-code" target="_blank" rel="license"><img src="https://example.org/custom.png" alt="CC-BY-NC 3.0 (Aus)" /></a> CC-BY-NC 3.0 (Aus)'
    }

    @Unroll
    void 'test formatLicense renders raw value as plain text for unrecognised value "#license"'(String license) {
        when:
        def html = applyTemplate("<alatag:formatLicense license=\"${license}\"/>")

        then:
        html == license

        where:
        license << ['Custom', 'other', 'UNSPECIFIED', 'Creative Commons - license at record level']
    }

    void "test formatLicense returns nothing for blank license"() {
        when:
        def html = applyTemplate('<alatag:formatLicense license="${license}"/>', [license: null])

        then:
        html == ''
    }
}

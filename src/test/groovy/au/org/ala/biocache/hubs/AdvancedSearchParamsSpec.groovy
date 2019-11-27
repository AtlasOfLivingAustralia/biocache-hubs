/*
 * Copyright (C) 2019 Atlas of Living Australia
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

import spock.lang.Specification

/**
 * Tests for {@link au.org.ala.biocache.hubs.AdvancedSearchParams }
 */
class AdvancedSearchParamsSpec extends Specification {

    void "test combineTermsWithAND() method with different combinations"() {
        given: "create the advancedSearchParams object"
        def asp = new AdvancedSearchParams()
        expect: "parse into SOLR query string"
        parsed == asp.combineTermsWithAND(field, inputText)

        where:
        inputText                  | field     | parsed
        ""                         | "text"    | ""
        " "                        | ""        | ""
        "kangaroo"                 | "text"    | "text:kangaroo"
        "kangaroo"                 | ""        | "kangaroo"
        "blue red"                 | "text"    | "text:blue AND text:red"
        "blue red"                 | ""        | "blue AND red"
        "red green orange"         | "text"    | "text:red AND text:green AND text:orange"
        "acacia dealbata"          | "taxa"    | "taxa:acacia AND taxa:dealbata"
        "\"acacia dealbata\""      | "taxa"    | "taxa:\"acacia dealbata\""
        "\"acacia dealbata\""      | ""        | "\"acacia dealbata\""
        "\"acacia dealbata\" foo"  | "taxa"    | "taxa:\"acacia dealbata\" AND taxa:foo"
        " "                        | "taxa"    | ""
    }
}

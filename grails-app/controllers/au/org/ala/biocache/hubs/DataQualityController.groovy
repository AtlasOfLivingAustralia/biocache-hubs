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
import grails.core.GrailsApplication
import org.supercsv.cellprocessor.ift.CellProcessor
import org.supercsv.io.CsvListReader
import org.supercsv.io.ICsvListReader
import org.supercsv.prefs.CsvPreference

/**
 * Generate codes and metadata for the data quality checks.
 * Data is stored in the <a href="https://docs.google.com/spreadsheet/pub?key=0AjNtzhUIIHeNdHJOYk1SYWE4dU1BMWZmb2hiTjlYQlE">Data
 * Quality Checks Google spreadsheet</a>
 */
class DataQualityController {
    GrailsApplication grailsApplication
    def webServicesService
    def qualityService

    static responseFormats = [
            list: ['json']
    ]

    def index() {
        redirect action: "allCodes"
    }

    def allCodes() {
        render webServicesService.getAllCodes() as JSON
    }

}

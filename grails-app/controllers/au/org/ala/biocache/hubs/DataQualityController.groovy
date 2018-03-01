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

    def index() {
        redirect action: "allCodes"
    }

    def allCodes() {
        Map dataQualityCodes = [:]
        String dataQualityCsv = webServicesService.getDataQualityCsv() // cached
        ICsvListReader listReader = null

        try {
            listReader = new CsvListReader(new StringReader(dataQualityCsv), CsvPreference.STANDARD_PREFERENCE)
            listReader.getHeader(true) // skip the header (can't be used with CsvListReader)
            final CellProcessor[] processors = getProcessors()

            List<Object> dataQualityList
            while ((dataQualityList = listReader.read(processors)) != null ) {
                //log.debug("row: " + StringUtils.join(dataQualityList, "|"));
                Map<String, String> dataQualityEls = new HashMap<String, String>();
                if (dataQualityList.get(1) != null) {
                    dataQualityEls.put("name", (String) dataQualityList.get(1));
                }
                if (dataQualityList.get(3) != null) {
                    dataQualityEls.put("description", (String) dataQualityList.get(3));
                }
                if (dataQualityList.get(4) != null) {
                    dataQualityEls.put("wiki", (String) dataQualityList.get(4));
                }
                if (dataQualityList.get(0) != null) {
                    dataQualityCodes.put((String) dataQualityList.get(0), dataQualityEls);
                }
            }
        } finally {
            if (listReader != null) {
                listReader.close();
            }
        }

        render dataQualityCodes as JSON
    }

    /**
     * CellProcessor method as required by SuperCSV
     *
     * @return
     */
    private static CellProcessor[] getProcessors() {
        final CellProcessor[] processors = [
            null, // col 1
            null, // col 2
            null, // col 3
            null, // col 4
            null, // col 5
            null, // col 6
            null, // col 7
            null, // col 8
            null, // col 9
            null, // col 10
            null, // col 11
            null, // col 12
            null, // col 13
            null, // col 14
            null, // col 15
       ]

        return processors
    }
}

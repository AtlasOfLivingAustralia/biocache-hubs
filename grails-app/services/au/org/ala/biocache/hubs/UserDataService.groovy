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

class UserDataService {
    def grailsApplication
    def webService

    def get(userId, type) {

        def data = [:]

        if (userId && grailsApplication.config.userdetails.baseUrl) {
            try {
                def resp = webService.get(grailsApplication.config.getProperty('userdetails.baseUrl') + '/property/getProperty' +
                        "?alaId=${userId}&name=${URLEncoder.encode(grailsApplication.config.getProperty('info.app.name') +'.'+ type, "UTF-8")}")

                if (resp?.resp && resp?.resp[0]?.value && resp?.resp[0]?.value) {
                    data = JSON.parse(resp?.resp[0]?.value)
                }
            } catch (err) {
                //fail with only a log entry
                log.error("failed to get user property ${userId}:${grailsApplication.config.getProperty('info.app.name') +'.'+ type} ${err.getMessage()}", err)
            }
        }

        data
    }

    // return value indicates if set succeeds
    boolean set(userId, type, data) {
        if (userId && grailsApplication.config.getProperty('userdetails.baseUrl')) {
            def response = webService.post(grailsApplication.config.getProperty('userdetails.baseUrl') + '/property/saveProperty', null,
                    [alaId: userId, name: grailsApplication.config.getProperty('info.app.name') +'.'+ type, value: (data as JSON).toString()])

            return response?.statusCode == 200
        }
        return false
    }
}

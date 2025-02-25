/*
 * Copyright (C) 2014 Atlas of Living Australia
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

import au.org.ala.web.UserDetails
import grails.converters.JSON
import org.grails.web.json.JSONArray

class AssertionsController {
    def webServicesService, authService

    static allowedMethods = [addAssertion: "POST", deleteAssertion: "POST"]

    def index() {}

    /**
     * Create combined assertions JSON web service from the user and quality assertion services
     * on biocache-service.
     * Note: mapped to URL: /assertions/$id to avoid CAS cookie check
     *
     * @param id
     * @return
     */
    def assertions(String id) {
        JSONArray userAssertions = webServicesService.getUserAssertions(id)
        Boolean hasClubView = request.isUserInRole("${grailsApplication.config.getProperty('clubRoleForHub')}")
        String userAssertionStatus = webServicesService.getRecord(id, hasClubView)?.raw.userAssertionStatus
        Map combined = [userAssertions: userAssertions ?: [], assertionQueries: [], userAssertionStatus: userAssertionStatus ?: ""]
        render combined as JSON
    }

    /**
     * Add a new assertion (POST). Taken from hubs-webapp
     *
     * @return
     */
    def addAssertion() {
        String recordUuid = params.recordUuid
        String code = params.code
        String comment = params.comment ?: ''
        String userAssertionStatus = params.userAssertionStatus ?: ""
        String assertionUuid = params.assertionUuid ?: ""
        String relatedRecordId = params.relatedRecordId ?: ''
        String relatedRecordReason = params.relatedRecordReason ?: ''
        String updateId = params.updateId ?: ''
        UserDetails userDetails = authService?.userDetails() // will return null if not available/not logged in

        if (recordUuid && code && userDetails) {

            if (code == '20020' && !relatedRecordId) {
                render(status: 400, text: 'Duplicate record id not provided')
            }

            if (code == '20020' && !relatedRecordReason) {
                render(status: 400, text: 'Duplicate record reason not provided')
            }

            log.info("Adding assertion to UUID: ${recordUuid}, code: ${code}, comment: ${comment}, userAssertionStatus: ${userAssertionStatus}, userId: ${userDetails.userId}, userEmail: ${userDetails.email}")
            Map postResponse = webServicesService.addAssertion(recordUuid, code, comment, userDetails.userId, userDetails.displayName, userAssertionStatus, assertionUuid, relatedRecordId, relatedRecordReason, updateId)

            if (postResponse.statusCode == 201) {
                log.info("Called REST service. Assertion should be added")
                render(status: postResponse.statusCode, text: 'Assertion added')
            } else {
                log.error "Unexpected error: ${postResponse.statusCode} (${postResponse.statusCode.class.name}) : ${postResponse.statusMsg}"
                render(status: postResponse.statusCode, text: postResponse.statusMsg)
            }
        } else {
            def errorMsg = (!userDetails) ?
                    "User details not found" :
                    "Required parameters not provided: ${(!recordUuid) ? 'recordUuid' : ''} ${(!code) ? 'code' : ''}"
            log.warn("Unable to add assertions. ${errorMsg}.")

            render(status: 400, text: errorMsg)
        }
    }

    /**
     * Delete an assertion (POST). Taken from hubs-webapp
     *
     * @return
     */
    def deleteAssertion() {
        String recordUuid = params.recordUuid
        String assertionUuid = params.assertionUuid

        if (recordUuid && assertionUuid) {
            log.info("Deleting assertion with assertionUuid: ${assertionUuid} & recordUuid: ${recordUuid}")
            Map postResponse = webServicesService.deleteAssertion(recordUuid, assertionUuid)

            if (postResponse.statusCode == 200) {
                log.info("Called REST service. Assertion should be deleted")
                render(status: postResponse.statusCode, text: 'Assertion deleted')
            } else {
                log.error "Unexpected error: ${postResponse.statusCode} (${postResponse.statusCode.class.name}) : ${postResponse.statusMsg}"
                render(status: postResponse.statusCode, text: postResponse.statusMsg)
            }
        } else {
            def errorMsg = "Required parameters not provided: ${(!recordUuid) ? 'recordUuid' : ''} ${(!assertionUuid) ? 'assertionUuid' : ''}"
            log.warn("Unable to add assertions. ${errorMsg}.")

            render(status: 400, text: errorMsg)
        }
    }
}

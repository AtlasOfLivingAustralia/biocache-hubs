package au.org.ala.biocache.hubs

import grails.converters.JSON
import org.codehaus.groovy.grails.web.json.JSONArray

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
        JSONArray qualityAssertions = webServicesService.getQueryAssertions(id)
        Map combined = [userAssertions: userAssertions?:[], assertionQueries: qualityAssertions?:[]]

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
        String comment = params.comment?:''
        Map userDetails = authService?.userDetails() // will return null if not available/not logged in

        if (recordUuid && code && userDetails) {
            log.info("Adding assertion to UUID: ${recordUuid}, code: ${code}, comment: ${comment}, userId: ${userDetails.userId}, userEmail: ${userDetails.email}")
            Map postResponse = webServicesService.addAssertion(recordUuid, code, comment, userDetails.userId, userDetails.userDisplayName)

            if (postResponse.statusCode == 201) {
                log.info("****** Called REST service. Assertion should be added" )
                render(status: postResponse.statusCode, text:'Assertion added')
            } else {
                log.error "Unexpected error: ${postResponse.statusCode} (${postResponse.statusCode.class.name}) : ${postResponse.statusMsg}"
                render(status: postResponse.statusCode, text: postResponse.statusMsg)
            }
        } else {
            def errorMsg = (!userDetail) ?
                    "User details not found" :
                    "Required parameters not provided: ${(!recordUuid) ? 'recordUuid' : ''} ${(!code) ? 'code' : ''}"
            log.warn("****** Unable to add assertions. ${errorMsg}." )

            render(status:400, text: errorMsg)
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
                log.info("****** Called REST service. Assertion should be deleted" )
                render(status: postResponse.statusCode, text:'Assertion deleted')
            } else {
                log.error "Unexpected error: ${postResponse.statusCode} (${postResponse.statusCode.class.name}) : ${postResponse.statusMsg}"
                render(status: postResponse.statusCode, text: postResponse.statusMsg)
            }
        } else {
            def errorMsg = "Required parameters not provided: ${(!recordUuid) ? 'recordUuid' : ''} ${(!assertionUuid) ? 'assertionUuid' : ''}"
            log.warn("****** Unable to add assertions. ${errorMsg}." )

            render(status:400, text: errorMsg)
        }
    }
}

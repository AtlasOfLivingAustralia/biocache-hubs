package au.org.ala.biocache.hubs

import grails.converters.JSON

class WebserviceController {
    def webServicesService, authService

    def getAlerts() {
        String userId = authService?.getUserId()
        if (userId == null) {
            response.status = 404
            render ([error: 'userId must be supplied to get alerts'] as JSON)
        } else {
            render webServicesService.getAlerts(userId) as JSON
        }
    }

    def subscribeMyAnnotation() {
        String userId = authService?.getUserId()
        if (userId == null) {
            response.status = 404
            render ([error: 'userId must be supplied to add alert'] as JSON)
        } else {
            render webServicesService.subscribeMyAnnotation(userId) as JSON
        }
    }

    def unsubscribeMyAnnotation() {
        String userId = authService?.getUserId()
        if (userId == null) {
            response.status = 404
            render ([error: 'userId must be supplied to delete alert'] as JSON)
        } else {
            render webServicesService.unsubscribeMyAnnotation(userId) as JSON
        }
    }

    def getStates() {
        render webServicesService.getStates(params.country) as JSON
    }
}

/*
 * Copyright (C) 2021 Atlas of Living Australia
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

import grails.converters.JSON

/**
 * Controller for web services
 */
class WebserviceController {
    def webServicesService, authService

    /**
     * Get alerts current user subscribed to from alert service.
     */
    def getAlerts() {
        String userId = authService?.getUserId()
        if (userId == null) {
            response.status = 404
            render ([error: 'userId must be supplied to get alerts'] as JSON)
        } else {
            render webServicesService.getAlerts(userId) as JSON
        }
    }

    /**
     * Subscribe current user to my annotation alert.
     */
    def subscribeMyAnnotation() {
        String userId = authService?.getUserId()
        if (userId == null) {
            response.status = 404
            render ([error: 'userId must be supplied to add alert'] as JSON)
        } else {
            render webServicesService.subscribeMyAnnotation(userId) as JSON
        }
    }

    /**
     * Unsubscribe current user from my annotation alert.
     */
    def unsubscribeMyAnnotation() {
        String userId = authService?.getUserId()
        if (userId == null) {
            response.status = 404
            render ([error: 'userId must be supplied to delete alert'] as JSON)
        } else {
            render webServicesService.unsubscribeMyAnnotation(userId) as JSON
        }
    }

    /**
     * Get the list of states belong to provided country.
     *
     * @param country - name of the country
     */
    def getStates(String country) {
        render webServicesService.getStates(country) as JSON
    }
}

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

/**
 * Controller for occurrence searches and records
 */
class UserController {

    def authService
    def userDataService

    def set(String type) {
        def userId = authService.getUserId()
        def data = request.JSON

        if (!userId) {
            render status: 403
        } else if (data && userId) {
            userDataService.set(userId, type, data)
            render data as JSON
        } else {
            render status: 404
        }
    }

    def get(String type) {
        def userId = authService.getUserId()

        if (!userId) {
            render status: 403
        } else if (userId) {
            def data = userDataService.get(userId, type)
            render data as JSON
        } else {
            render status: 404
        }
    }
}

/*
 * Copyright (C) 2015 Atlas of Living Australia
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

class UserService {
    def authService
    /**
     * Get both email and displayName for a numeric user id.  Preferring to use the auth service
     * unless it's unavailable, then fall back to database
     *
     * @param userid The ALA userid to lookup
     */
    def detailsForUserId(String userid) {
        if (!userid) return [displayName: '', email: '']
        else if ('system' == userid) return [displayName: userid, email: userid]

        UserDetails details = null

        try {
            details = authService.getUserForUserId(userid)
        } catch (Exception e) {
            log.warn("couldn't get user details from web service", e)
        }

        if (details) return [displayName: details?.displayName ?: '', email: details?.userName ?: '']
        else {
            log.warn('could not find user details')
            return [displayName: userid, email: userid]
        }
    }}

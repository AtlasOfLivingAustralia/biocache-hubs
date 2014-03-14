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

import grails.plugin.cache.CacheEvict
import org.springframework.beans.propertyeditors.CustomDateEditor
import org.springframework.web.bind.WebDataBinder
import org.springframework.web.bind.annotation.InitBinder

import java.text.SimpleDateFormat

class AdminController {
    def scaffold = true
    def facetsCacheService, outageService

    def index() {
        render "Not available to the public"
    }

    @CacheEvict(value='biocacheCache', allEntries=true)
    def clearBiocacheCache() {
        render(text:"biocacheCache cache cleared")
    }

    @CacheEvict(value='collectoryCache', allEntries=true)
    def clearCollectoryCache() {
        render(text:"collectoryCache cache cleared")
    }

    @CacheEvict(value='longTermCache', allEntries=true)
    def clearLongTermCache() {
        render(text:"longTermCache cache cleared")
    }

    def clearFacetsCache() {
        facetsCacheService.clearCache()
        redirect(action: "clearLongTermCache") // clear webservice cache as well
    }

    /**
     * InitBinder to provide data conversion when binding
     *
     * @param binder
     */
    @InitBinder
    public void initBinder(WebDataBinder binder) {
        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd")
        dateFormat.setLenient(false)
        binder.registerCustomEditor(Date.class, new CustomDateEditor(dateFormat, false))
    }

    def outageMessage(OutageBanner outageBanner) {
        if ("GET".equals(request.getMethod())) {
            // display data from service
            log.debug("/outageMessage GET: " + outageBanner)
            outageBanner = outageService.getOutageBanner()
        } else {
            // POST - save form data
            log.debug("/outageMessage POST: " + outageBanner)
            outageService.clearOutageCache() // clear the cache so changes are instant
            outageService.setOutageBanner(outageBanner)
        }

        [outageBanner: outageBanner]
    }
}

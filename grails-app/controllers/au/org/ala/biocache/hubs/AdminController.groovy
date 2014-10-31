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
import grails.util.Environment
import org.springframework.beans.propertyeditors.CustomDateEditor
import org.springframework.core.io.support.PathMatchingResourcePatternResolver
import org.springframework.web.bind.WebDataBinder
import org.springframework.web.bind.annotation.InitBinder

import java.text.SimpleDateFormat

/**
 * Admin functions - should be protected by login and ROLE_ADMIN or equil.
 */
class AdminController {
    def scaffold = true
    def facetsCacheService, outageService, authService, webServicesService
    def beforeInterceptor = [action:this.&auth]

    /**
     * Before interceptor to check for roles
     *
     * @return
     */
    private auth() {
        if (!grailsApplication.config.security.cas.casServerName && grailsApplication.config.security.cas.bypass) {
            // Standard Grails config - bypass
            true
        } else if (!grailsApplication.config.casServerName && grailsApplication.config.disableCAS) {
            // External config - bypass
            true
        } else if (!authService?.userInRole(grailsApplication.config.auth.admin_role)) {
            log.debug "redirecting to index..."
            flash.message = "You are not authorised to access the page: ${params.controller}/${params.action?:''}."
            redirect(controller: "home", action: "index")
            false
        } else {
            true
        }
    }

    def index() {
        // [ message: "not used" ]
    }

    def clearAllCaches() {
        def message = doClearAllCaches()
        flash.message = message.replaceAll("\n","<br/>")
        redirect(action:'index')
    }

    private String doClearAllCaches() {
        def message = "Clearing all caches...\n"
        message += webServicesService.doClearCollectoryCache()
        message += webServicesService.doClearLongTermCache()
        message += doClearFacetsCache()
        message
    }

    def clearCollectoryCache() {
        flash.message = webServicesService.doClearCollectoryCache()
        redirect(action:'index')
    }

    def clearLongTermCache() {
        flash.message = webServicesService.doClearLongTermCache()
        redirect(action:'index')
    }

    def clearFacetsCache() {
        flash.message = doClearFacetsCache()
        redirect(action:'index')
    }

    def doClearFacetsCache() {
        facetsCacheService.clearCache()
        "facetsCache cache cleared\n"
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

    /**
     * Reload external config file
     */
    def reloadConfig = {
        // clear any cached external config
        doClearAllCaches()
        String configVarStr = params.configVar
        List configVar = configVarStr.split(',')


        // reload system config
        def configLocation = "file:${grailsApplication.config.default_config}"
        def resolver = new PathMatchingResourcePatternResolver()
        def resource = resolver.getResource(configLocation)
        def stream = null

        try {
            stream = resource.getInputStream()
            ConfigSlurper configSlurper = new ConfigSlurper(Environment.current.name)
            if(resource.filename.endsWith('.groovy')) {
                def newConfig = configSlurper.parse(stream.text)
                grailsApplication.getConfig().merge(newConfig)
            }
            else if(resource.filename.endsWith('.properties')) {
                def props = new Properties()
                props.load(stream)
                def newConfig = configSlurper.parse(props)
                grailsApplication.getConfig().merge(newConfig)
            }

            String res = ""
            configVar.each {
                res += "${it} = " + grailsApplication.config.flatten()."${it}" + " <br/>"
            }

            chain(action:'index', model:[config: res], params: [configVar: configVarStr])
        }
        catch (FileNotFoundException fnf) {
            log.error "No external config to reload configuration. Looking for ${configLocation}", fnf
            flash.message = "No external config to reload configuration. Looking for ${configLocation}"
            redirect(action:'index')
        }
        catch (Exception gre) {
            log.error "Unable to reload configuration. Please correct problem and try again: ${gre}", gre
            flash.message =  "Unable to reload configuration - " + gre.getMessage()
            redirect(action:'index')
        }
        finally {
            stream?.close()
        }
    }
}

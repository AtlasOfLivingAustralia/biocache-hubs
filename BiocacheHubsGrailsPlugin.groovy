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

import au.org.ala.biocache.hubs.ExtendedPluginAwareResourceBundleMessageSource
import grails.util.Environment

class BiocacheHubsGrailsPlugin {
    // the plugin version
    def version = "0.7"
    // the version or versions of Grails the plugin is designed for
    def grailsVersion = "2.3 > *"
    // resources that are excluded from plugin packaging
    def pluginExcludes = [
            "grails-app/views/error.gsp"
    ]

    // TODO Fill in these fields
    def title = "Biocache Hubs Plugin" // Headline display name of the plugin
    def author = "Nick dos Remedios"
    def authorEmail = "nick.dosremedios@csiro.au"
    def description = '''\
A client web application for searching and displaying biodiversity data from the
Atlas of Living Australia (ALA). Data access is via JSON REST web services from
the ALA biocache-service app (no local DB is required for this app).
'''

    // URL to the plugin's documentation
    def documentation = "http://code.google.com/p/ala-hubs/wiki/BiocacheHubsPlugin"

    // Extra (optional) plugin metadata

    // License: one of 'APACHE', 'GPL2', 'GPL3'
    def license = "MPL2"

    // Details of company behind the plugin (if there is one)
    def organization = [ name: "Atlas of Living Australia", url: "http://www.ala.org.au/" ]

    // Any additional developers beyond the author specified above.
    def developers = [ [ name: "Dave Martin", email: "david.martin@csiro.au" ]]

    // Location of the plugin's issue tracker.
    def issueManagement = [ system: "Google Code", url: "https://code.google.com/p/ala/issues/list" ]

    // Online location of the plugin's browseable source code.
    def scm = [ url: "http://ala-hubs.googlecode.com/svn/trunk/biocache-hubs" ]

    def loadBefore = ['alaWebTheme']

    def doWithWebDescriptor = { xml ->
        // Note this code only gets executed at compile time (not runtime)
    }

    def doWithSpring = {
        def config = application.config

        // EhCache settings
        if (!config.grails.cache.config) {
            config.grails.cache.config = {
                defaults {
                    eternal false
                    overflowToDisk false
                    maxElementsInMemory 20000
                    timeToLiveSeconds 3600
                }
                cache {
                    name 'biocacheCache'
                    timeToLiveSeconds (60 * 5)
                    maxElementsInMemory 20000
                    overflowToDisk true
                }
                cache {
                    name 'collectoryCache'
                    timeToLiveSeconds (3600 * 4)
                }
                cache {
                    name 'longTermCache'
                    timeToLiveSeconds (3600 * 12)
                }
                cache {
                    name 'outageCache'
                    timeToLiveSeconds (3600 * 24 * 7)
                }
            }
        }

        // Load the "sensible defaults"
        //println "config.skin = ${config.skin}"
        def loadConfig = new ConfigSlurper(Environment.current.name).parse(application.classLoader.loadClass("defaultConfig"))
        application.config = loadConfig.merge(config) // client app will now override the defaultConfig version
        //application.config.merge(loadConfig) //
        //println "config.security = ${config.security}"

        // Custom message source
        messageSource(ExtendedPluginAwareResourceBundleMessageSource) {
            basenames = ["classpath:grails-app/i18n/messages","${application.config.biocache.baseUrl}/facets/i18n"] as String[]
            cacheSeconds = 300
            useCodeAsDefaultMessage = true
        }
    }

    def doWithDynamicMethods = { ctx ->
        // TODO Implement registering dynamic methods to classes (optional)
    }

    def doWithApplicationContext = { ctx ->
        // TODO Implement post initialization spring config (optional)
    }

    def onChange = { event ->
        // TODO Implement code that is executed when any artefact that this plugin is
        // watching is modified and reloaded. The event contains: event.source,
        // event.application, event.manager, event.ctx, and event.plugin.
    }

    def onConfigChange = { event ->
        //this.mergeConfig(application)
        // TODO Implement code that is executed when the project configuration changes.
        // The event is the same as for 'onChange'.
    }

    def onShutdown = { event ->
        // TODO Implement code that is executed when the application shuts down (optional)
    }
}

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


import au.org.ala.biocache.hubs.EnglishValueConverter
import au.org.ala.biocache.hubs.ExtendedPluginAwareResourceBundleMessageSource
import grails.util.Environment

class BiocacheHubsGrailsPlugin {
    // the plugin version
    def version = "0.75"
    // the version or versions of Grails the plugin is designed for
    def grailsVersion = "2.3 > *"
    // resources that are excluded from plugin packaging
    def pluginExcludes = [
            "grails-app/views/error.gsp"
    ]

    def title = "Biocache Hubs Plugin" // Headline display name of the plugin
    def author = "Nick dos Remedios"
    def authorEmail = "nick.dosremedios@csiro.au"
    def description = '''\
A Grails plugin to provide the core functionality for searching and displaying biodiversity data from
biocache web services. Data access is via JSON REST web services
from the ALA biocache-service app (no local DB is required for this app).
'''

    // URL to the plugin's documentation
    def documentation = "https://github.com/AtlasOfLivingAustralia/biocache-hubs"

    // License: one of 'APACHE', 'GPL2', 'GPL3'
    def license = "MPL2"

    // Details of company behind the plugin (if there is one)
    def organization = [ name: "Atlas of Living Australia", url: "http://www.ala.org.au/" ]

    // Any additional developers beyond the author specified above.
    def developers = [
            [ name: "Dave Martin", email: "david.martin@csiro.au" ],
            [ name: "Dave Baird", email: "david.baird@csiro.au" ]
    ]

    // Location of the plugin's issue tracker.
    def issueManagement = [ system: "Google Code", url: "https://github.com/AtlasOfLivingAustralia/biocache-hubs/issues" ]

    // Online location of the plugin's browseable source code.
    def scm = [ url: "https://github.com/AtlasOfLivingAustralia/biocache-hubs" ]

    def loadBefore = ['alaWebTheme']
    def loadAfter = ['dataBinding'] // needed for custom ValueConverter bean

    def doWithWebDescriptor = { xml ->
        // Note this code only gets executed at compile time (not runtime)
    }

    def doWithSpring = {
        def config = application.config

        // EhCache settings
        if (!config.grails.cache.config) {
            config.grails.cache.config = {
                defaults {1
                    eternal false
                    overflowToDisk false
                    maxElementsInMemory 10000
                    timeToLiveSeconds 3600
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

        // Apache proxyPass & cached-resources seems to mangle image URLs in plugins, so we exclude caching it
        application.config.grails.resources.mappers.hashandcache.excludes = ["**/images/*.*","**/eya-images/*.*"]
        // include fonts in resources
        application.config.grails.resources.adhoc.patterns = ['/images/*', '/css/*', '/js/*', '/plugins/*', '/fonts/*']

        // Load the "sensible defaults"
        //println "config.skin = ${config.skin}"
        def loadConfig = new ConfigSlurper(Environment.current.name).parse(application.classLoader.loadClass("defaultConfig"))
        application.config = loadConfig.merge(config) // client app will now override the defaultConfig version
        //application.config.merge(loadConfig) //
        //println "config.security = ${config.security}"

        // Custom message source
        messageSource(ExtendedPluginAwareResourceBundleMessageSource) {
            basenames = ["WEB-INF/grails-app/i18n/messages","${application.config.biocache.baseUrl}/facets/i18n"] as String[]
            cacheSeconds = (60 * 60 * 6) // 6 hours
            useCodeAsDefaultMessage = false
        }

        // Define Custom ValueConverter beans (force EN formatting of Floats)
        "defaultGrailsjava.lang.FloatConverter"(EnglishValueConverter) // for Float
        defaultGrailsfloatConverter(EnglishValueConverter)             // for float

        println  "grails.resources.work.dir = " + config.grails.resources.work.dir

        // check custom resources cache dir for permissions
        if (config.grails.resources.work.dir) {
            if (new File(config.grails.resources.work.dir).isDirectory()) {
                // cache dir exists - check if its writable
                if (!new File(config.grails.resources.work.dir).canWrite()) {
                    //grailsConsole.error "grails.resources.work.dir (${config.grails.resources.work.dir}) is NOT WRITABLE, please fix this!"
                    println  "grails.resources.work.dir (${config.grails.resources.work.dir}) is NOT WRITABLE, please fix this!"
                }
            } else {
                // check we can create the directory
                if (!new File(config.grails.resources.work.dir).mkdir()) {
                    println  "grails.resources.work.dir (${config.grails.resources.work.dir}) cannot be created, please fix this!"
                }
            }
        }
    }

    def doWithDynamicMethods = { ctx ->
    }

    def doWithApplicationContext = { ctx ->
    }

    def onChange = { event ->
    }

    def onConfigChange = { event ->
    }

    def onShutdown = { event ->
    }
}

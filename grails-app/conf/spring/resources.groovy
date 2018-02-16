/*
 * Copyright (C) 2017 Atlas of Living Australia
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

import au.org.ala.biocache.hubs.ExtendedPluginAwareResourceBundleMessageSource

beans = {
    // Custom message source - This is a duplicate bean def - see original in: src/main/groovy/au/org/ala/biocache/hubs/BiocacheHubsGrailsPlugin.groovy
//    customMessageSource(ExtendedPluginAwareResourceBundleMessageSource) {
//        // The standard messageSource will already use "WEB-INF/grails-app/i18n/messages"
//        // ExtendedPluginAwareResourceBundleMessageSource uses messageSource as an additional backing message source
//        basename = "${application.config.biocache.baseUrl}/facets/i18n"
//        cacheSeconds = (60 * 60 * 6) // 6 hours
//        useCodeAsDefaultMessage = false
//    }
}
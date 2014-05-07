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

import org.codehaus.groovy.grails.context.support.PluginAwareResourceBundleMessageSource

/**
 * Extend PluginAwareResourceBundleMessageSource so we can access the (protected)
 * getMergedProperties() method to export all i18n messages for JS usage.
 *
 * @author "Nick dos Remedios <Nick.dosRemedios@csiro.au>"
 */
class ExtendedPluginAwareResourceBundleMessageSource extends PluginAwareResourceBundleMessageSource {
    /**
     * Provide a complete listing of properties for a given locale, as a Map
     * Client app properties override those from this plugin
     *
     * @param locale
     * @return
     */
    Map<String, String> listMessageCodes(Locale locale) {
        Properties pluginProperties = getMergedPluginProperties(locale).properties
        Properties properties = getMergedProperties(locale).properties
        return pluginProperties.plus(properties)
    }
}
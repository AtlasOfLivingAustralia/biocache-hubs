/*
 * Copyright (C) 2014 Atlas of Living Australia
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

import grails.plugin.cache.Cacheable

/**
 * A service that provides a java.util.Map representation of the i18n
 * messages for a given locale (cached). The main use for this service is
 * to provide a faster lookup for many i18n calls in a taglib, due to performance
 * issues with the <g.message> tag (too slow).
 */
class MessageSourceCacheService {
    def messageSource // injected with a ExtendedPluginAwareResourceBundleMessageSource (see plugin descriptor file)

    @Cacheable('longTermCache')
    def getMessagesMap(Locale locale) {

        if (!locale) {
            locale = new Locale("en","us")
        }

        def messagesMap = messageSource.listMessageCodes(locale)
        //log.debug "messagesMap size = ${messagesMap.size()}"
        //log.debug "test: search.facets.heading = ${messageSource.getMessage('search.facets.heading',null, locale)}"

        messagesMap
    }

    /**
     * Trigger the message source cache to be reset (different to the @Cacheable cache)
     * which effectively grabs a new copy from biocache-service (base properties) and then adds to that from the
     * i18n messages in the local grails app.
     *
     * @return
     */
    void clearMessageCache() {
        messageSource.clearCache()
    }
}
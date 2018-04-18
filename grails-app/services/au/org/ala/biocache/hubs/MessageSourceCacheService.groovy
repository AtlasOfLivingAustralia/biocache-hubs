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
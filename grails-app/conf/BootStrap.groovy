import grails.util.Holders

class BootStrap {
    def grailsApplication, messageSource
    def init = { servletContext ->
        // sanity check for external properties
//        log.debug "exploreYourArea.location = ${grailsApplication.config.exploreYourArea.location}"
//        //log.error "config.default_config = ${grailsApplication.config.default_config}"
//        //log.error "config = ${Holders.config}"
//        log.error "config.security.cas.bypass = ${grailsApplication.config.security.cas.bypass}"
//        log.debug "servername = ${grailsApplication.config.servername}"
//        //log.warn "resources.only = ${grailsApplication.config.resources.only}"
//        // sanity check for i18n
//        log.debug "biocache-service i18n check - facet.pestStatus = ${messageSource.getMessage('facet.pestStatus', null, Locale.ENGLISH)}"
//        // local i18n value override check
//        log.debug "biocache-service i18n check - facet.state = ${messageSource.getMessage('facet.state', null, Locale.ENGLISH)}" // State or Territory vs State/Territory
//        // local only check
//        log.debug "biocache-service i18n check - confirm.message = ${messageSource.getMessage('default.button.delete.confirm.message', null, Locale.ENGLISH)}"
    }
    def destroy = {
    }
}

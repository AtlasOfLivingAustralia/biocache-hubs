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

import grails.validation.ValidationException

/**
 * Admin functions - should be protected by login and ROLE_ADMIN or equiv.
 * See {@link au.org.ala.biocache.hubs.AdminInterceptor}
 */
class AdminController {
    def facetsCacheService
    def webServicesService
    def messageSourceCacheService
    def qualityService

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
        message += doClearPropertiesCache()
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

    def clearPropertiesCache() {
        flash.message = doClearPropertiesCache()
        redirect(action:'index')
    }

    def doClearFacetsCache() {
        facetsCacheService.clearCache()
        "facetsCache cache cleared\n"
    }

    def doClearPropertiesCache() {
        messageSourceCacheService.clearMessageCache()
        "i18n messages cache cleared\n"
    }

    def "data-quality-filters"() {
        respond QualityCategory.list(sort: 'id', lazy: false)
    }

    def saveQualityCategory(QualityCategory qualityCategory) {
        try {
            qualityService.createOrUpdate(qualityCategory)
        } catch (ValidationException e) {
            flash.errors = e.errors
        }
        redirect(action: 'data-quality-filters')
    }

    def enableQualityCategory() {
        log.error "{}", params
        def qc = QualityCategory.get(params.long('id'))
        qc.enabled = params.boolean('enabled', false)
        qc.save(flush: true)
        redirect(action: 'data-quality-filters')
    }

    def deleteQualityCategory(QualityCategory qualityCategory) {
        qualityService.deleteCategory(qualityCategory)
        redirect(action: 'data-quality-filters')
    }

    def saveQualityFilter(QualityFilter qualityFilter) {
        try {
            qualityService.createOrUpdateFilter(qualityFilter)
        } catch (ValidationException e) {
            flash.errors = e.errors
        } catch (IllegalStateException e) {
            return render(status: 400, text: 'invalid params')
        }
        redirect(action: 'data-quality-filters')
    }

    def deleteQualityFilter() {
        def id = params.long('id')
        if (!id) {
            return render(status: 404, text: 'filter not found')
        }
        qualityService.deleteFilter(id)
        redirect(action: 'data-quality-filters')
    }

    def enableQualityFilter() {
        log.error "{}", params
        def qf = QualityFilter.get(params.long('id'))
        qf.enabled = params.boolean('enabled', false)
        qf.save(flush: true)
        redirect(action: 'data-quality-filters')
    }
}

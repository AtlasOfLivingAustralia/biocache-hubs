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

    def clearRecordCountCache() {
        qualityService.clearRecordCountCache()
        flash.message = "record count cache cleared\n"
        redirect(action: 'index')
    }

    def dataQualityFilters() {
        respond QualityCategory.list(sort: 'id', lazy: false), model: [ 'qualityFilterStrings' : qualityService.enabledFiltersByLabel, 'errors': flash.errors, 'options': webServicesService.getAllOccurrenceFields() ]
    }

    def saveQualityCategory(QualityCategory qualityCategory) {
        withForm {
            try {
                qualityService.createOrUpdateCategory(qualityCategory)
            } catch (ValidationException e) {
                flash.errors = e.errors
            }
        }.invalidToken {
            // bad request
            log.debug("ignore duplicate save category request. name:{}, label:{}", qualityCategory.name, qualityCategory.label)
        }
        redirect(action: 'dataQualityFilters')
    }

    def enableQualityCategory() {
        withForm {
            def qc = QualityCategory.get(params.long('id'))
            qc.enabled = params.boolean('enabled', false)
            qc.save(flush: true)
        }.invalidToken {
            // bad request
            log.debug("ignore duplicate enable category request")
        }
        redirect(action: 'dataQualityFilters')
    }

    def deleteQualityCategory(QualityCategory qualityCategory) {
        withForm {
            qualityService.deleteCategory(qualityCategory)
        }.invalidToken {
            // bad request
            log.debug("ignore duplicate delete category request. name:{}, label:{}", qualityCategory.name, qualityCategory.label)
        }
        redirect(action: 'dataQualityFilters')
    }

    def saveQualityFilter(QualityFilter qualityFilter) {
        withForm {
            try {
                qualityService.createOrUpdateFilter(qualityFilter)
            } catch (ValidationException e) {
                flash.errors = e.errors
            } catch (IllegalStateException e) {
                return render(status: 400, text: 'invalid params')
            }
        }.invalidToken {
            // bad request
            log.debug("ignore duplicate save filter request. description:{}, filter:{}", qualityFilter.description, qualityFilter.filter)
        }
        redirect(action: 'dataQualityFilters')
    }

    def deleteQualityFilter() {
        withForm {
            def id = params.long('id')
            if (!id) {
                return render(status: 404, text: 'filter not found')
            }
            qualityService.deleteFilter(id)
        }.invalidToken {
            log.debug("ignore duplicate delete filter request")
        }
        redirect(action: 'dataQualityFilters')
    }

    def enableQualityFilter() {
        withForm {
            def qf = QualityFilter.get(params.long('id'))
            qf.enabled = params.boolean('enabled', false)
            qf.save(flush: true)
        }.invalidToken {
            // bad request
            log.debug("ignore duplicate enable filter request")
        }
        redirect(action: 'dataQualityFilters')
    }
}

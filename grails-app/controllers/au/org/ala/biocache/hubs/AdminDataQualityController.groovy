/*
 * Copyright (C) 2020 Atlas of Living Australia
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

class AdminDataQualityController {

    def qualityService
    def webServicesService

    def filters() {
        def qp = QualityProfile.get(params.long('id'))
        respond QualityCategory.findAllByQualityProfile(qp, [sort: 'id', lazy: false]), model: [ 'qualityFilterStrings' : qualityService.getEnabledFiltersByLabel(qp.shortName), 'errors': flash.errors, 'options': webServicesService.getAllOccurrenceFields(), 'profile': qp ]
    }

    def profiles() {
        respond QualityProfile.list(sort: 'id'), model: ['errors': flash.errors]
    }

    def saveProfile(QualityProfile qualityProfile) {
        withForm {
            try {
                qualityService.createOrUpdateProfile(qualityProfile)
            } catch (ValidationException e) {
                flash.errors = e.errors
            }
        }.invalidToken {
            // bad request
            log.debug("ignore duplicate save profile request. name:{}, shortName:{}", qualityProfile.name, qualityProfile.shortName)
        }
        redirect(action: 'profiles')
    }

    def enableQualityProfile() {
        withForm {
            def qp = QualityProfile.get(params.long('id'))
            qp.enabled = params.boolean('enabled', false)
            qp.save(flush: true)
        }.invalidToken {
            // bad request
            log.debug("ignore duplicate enable category request")
        }
        redirect(action: 'profiles')
    }

    def setDefaultProfile() {
        withForm {
            qualityService.setDefaultProfile(params.long('id'))
        }.invalidToken {
            log.debug('set default profile invalid token')
        }
        redirect(action: 'profiles')
    }

    def deleteQualityProfile(QualityProfile qualityProfile) {
        withForm {
            qualityService.deleteProfile(qualityProfile)
        }.invalidToken {
            // bad request
            log.debug("ignore duplicate delete profile request. name: {}, shortname: {}", qualityProfile.name, qualityProfile.shortName)
        }
        redirect(action: 'profiles')
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
        redirect(action: 'filters', id: qualityCategory.qualityProfile.id)
    }

    def enableQualityCategory() {
        def qc = QualityCategory.get(params.long('id'))
        withForm {
            qc.enabled = params.boolean('enabled', false)
            qc.save(flush: true)
        }.invalidToken {
            // bad request
            log.debug("ignore duplicate enable category request")
        }
        redirect(action: 'filters', id: qc.qualityProfile.id)
    }

    def deleteQualityCategory(QualityCategory qualityCategory) {
        withForm {
            qualityService.deleteCategory(qualityCategory)
        }.invalidToken {
            // bad request
            log.debug("ignore duplicate delete category request. name:{}, label:{}", qualityCategory.name, qualityCategory.label)
        }
        redirect(action: 'filters', id: qualityCategory.qualityProfile.id)
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
        redirect(action: 'filters', id: qualityFilter.qualityCategory.qualityProfile.id)
    }

    def deleteQualityFilter() {
        def id = params.long('id')
        def profileId = params.long('profileId')
        withForm {
            if (!id) {
                return render(status: 404, text: 'filter not found')
            }
            qualityService.deleteFilter(id)
        }.invalidToken {
            log.debug("ignore duplicate delete filter request")
        }
        redirect(action: 'filters', id: profileId)
    }

    def enableQualityFilter() {
        def qf = QualityFilter.get(params.long('id'))
        withForm {
            qf.enabled = params.boolean('enabled', false)
            qf.save(flush: true)
        }.invalidToken {
            // bad request
            log.debug("ignore duplicate enable filter request")
        }
        redirect(action: 'filters', id: qf.qualityCategory.qualityProfile.id)
    }
}

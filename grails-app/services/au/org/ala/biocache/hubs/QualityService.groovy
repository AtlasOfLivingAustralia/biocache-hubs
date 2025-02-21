/*
 * Copyright (C) 2020 Atlas of Living Australia
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

import au.org.ala.dataquality.api.DataProfilesApi
import au.org.ala.dataquality.api.QualityServiceRpcApi
import au.org.ala.dataquality.client.ApiClient
import au.org.ala.dataquality.model.QualityCategory
import au.org.ala.dataquality.model.QualityFilter
import au.org.ala.dataquality.model.QualityProfile
import com.google.common.base.Stopwatch
import grails.plugin.cache.CacheEvict
import grails.plugin.cache.Cacheable
import org.springframework.beans.factory.annotation.Value
import retrofit2.Call
import retrofit2.HttpException

import javax.annotation.PostConstruct

/**
 * This service provides below functions
 * 1. wrap API calls to data-quality-filter-service
 * 2. get excluded counts of quality categories
 */
class QualityService {

    def webServicesService

    @Value('${dataquality.enabled}')
    boolean dataQualityEnabled

    @Value('${dataquality.baseUrl}')
    def dataQualityBaseUrl

    def grailsApplication

    QualityServiceRpcApi api
    DataProfilesApi dataProfilesApi

    @PostConstruct
    def init() {
        if (dataQualityEnabled) {
            def apiClient = new ApiClient()
            apiClient.adapterBuilder.baseUrl(dataQualityBaseUrl)
            apiClient.okBuilder.addInterceptor { chain ->
                def request = chain.request().newBuilder().addHeader('User-Agent', "${grailsApplication.config.getProperty('info.app.name')}/${grailsApplication.config.getProperty('info.app.version')}").build()
                chain.proceed(request)
            }
            api = apiClient.createService(QualityServiceRpcApi)
            dataProfilesApi = apiClient.createService(DataProfilesApi)
        }
    }

    Map<String, String> getEnabledFiltersByLabel(String profileName) {
        if (dataQualityEnabled) {
            return responseOrThrow(api.getEnabledFiltersByLabel(profileName))
        } else {
            return [:]
        }
    }

    List<String> getEnabledQualityFilters(String profileName) {
        if (dataQualityEnabled) {
            return responseOrThrow(api.getEnabledQualityFilters(profileName))
        } else {
            return []
        }
    }

    Map<String, List<QualityFilter>> getGroupedEnabledFilters(String profileName) {
        if (dataQualityEnabled) {
            return responseOrThrow(api.getGroupedEnabledFilters(profileName))
        } else {
            return [:]
        }

    }

    @Cacheable(value = 'qualityShortTermCache', key = { profileName })
    List<QualityCategory> findAllEnabledCategories(String profileName) {
        if (dataQualityEnabled) {
            return responseOrThrow(api.findAllEnabledCategories(profileName))
        } else {
            return []
        }
    }

    @Cacheable(value = 'qualityShortTermCache', key = { profileName })
    QualityProfile activeProfile(String profileName) {
        if (dataQualityEnabled) {
            return responseOrThrow(api.activeProfile(profileName))
        } else {
            return null
        }
    }

    String getJoinedQualityFilter(String profileName) {
        if (dataQualityEnabled) {
            return responseOrThrow(api.getJoinedQualityFilter(profileName))
        } else {
            return ''
        }
    }

    String getInverseCategoryFilter(QualityCategory category) {
        if (dataQualityEnabled) {
            return responseOrThrow(api.getInverseCategoryFilter(category.id?.toInteger()))
        } else {
            return ''
        }
    }

    @Cacheable(value = 'qualityShortTermCache', key = { profile.name })
    Map<String, String> getAllInverseCategoryFiltersForProfile(QualityProfile profile) {
        if (dataQualityEnabled) {
            return responseOrThrow(api.getAllInverseCategoryFiltersForProfile(profile.id?.toInteger()))
        } else {
            return [:]
        }
    }

    @Cacheable(value = 'qualityShortTermCache', key = { enabled })
    List<QualityProfile> findAllEnabledProfiles(boolean enabled) {
        if (dataQualityEnabled) {
            return responseOrThrow(dataProfilesApi.dataProfiles(null, null, null, null, enabled, null, null))
        } else {
            return []
        }
    }

    // QualityProfile.isDefault is not in the returned json (it's a bug should be fixed in dq-service side)
    // this is just a workaround: go through each enabled profile to match the name
    boolean isProfileEnabled(String profileShortName) {
        if (dataQualityEnabled) {
            def enabledProfiles = findAllEnabledProfiles(true)
            return enabledProfiles?.any { it.shortName == profileShortName }
        } else {
            return false
        }
    }

    boolean isProfileValid(profileName) {
        return profileName && isProfileEnabled(profileName)
    }

    @CacheEvict(value = 'excludedCountCache', allEntries = true)
    def clearRecordCountCache() {
        "record count cache cleared\n"
    }

    @Cacheable(value = 'excludedCountCache', key = { requestParams.toString() })
    def getExcludeCount(SpatialSearchRequestParams requestParams) {
        return webServicesService.fullTextSearch(requestParams)?.totalRecords
    }

    private Long countRecordsExcludedByLabel(List<String> otherLabels, SpatialSearchRequestParams requestParams) {
        def srp = requestParams.clone().with {
            it.pageSize = 1 // when it is 0 it will return 20 records
            it.start = 0
            it.flimit = 0
            it.facet = false
            it.sort = ''
            it.max = 0
            it.offset = 0
            it.disableQualityFilter = otherLabels
            it
        }
        grailsApplication.mainContext.getBean('qualityService').getExcludeCount(srp)
    }

    Long countTotalRecords(SpatialSearchRequestParams requestParams) {
        if (dataQualityEnabled) {
            def srp = requestParams.clone().with {
                it.pageSize = 1 // when it is 0 it will return 20 records
                it.start = 0
                it.flimit = 0
                it.facet = false
                it.sort = ''
                it.max = 0
                it.offset = 0
                it.disableQualityFilter = []
                it.disableAllQualityFilters = true
                it
            }
            grailsApplication.mainContext.getBean('qualityService').getExcludeCount(srp)
        } else {
            return 0
        }
    }

    Map<String, Long> getExcludeCount(List<QualityCategory> qualityCategories, SpatialSearchRequestParams requestParams) {
        if (dataQualityEnabled) {
            Stopwatch sw = Stopwatch.createStarted()

            def totalRecords = countTotalRecords(requestParams)
            def labels = qualityCategories*.label as Set
            def response = qualityCategories.collectEntries {
                def otherLabels = (labels - it.label) as List
                [(it.label): totalRecords - countRecordsExcludedByLabel(otherLabels, requestParams)]
            }
            log.debug("Quality Category facet counts took {}", sw)
            return response
        } else {
            return [:]
        }
    }

    Long getExcludeCount(String categoryLabel, List<QualityCategory> qualityCategories, SpatialSearchRequestParams requestParams) {
        def totalRecords = countTotalRecords(requestParams)
        def labels = qualityCategories*.label as Set
        return totalRecords - countRecordsExcludedByLabel((labels - categoryLabel) as List, requestParams)
    }

    private <T> T responseOrThrow(Call<T> call) {
        def response
        try {
            response = call.execute()
        } catch (IOException e) {
            log.error("IOException executing call {}", call.request(), e)
            throw new RuntimeException("IO Exception executing ${call.request()}", e)
        }
        if (response.successful) {
            return response.body()
        } else {
            log.error("Non-successful call {} returned response {}", call.request(), response)
            throw new HttpException(response)
        }
    }
}

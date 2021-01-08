package au.org.ala.biocache.hubs

import au.org.ala.dataquality.api.DataProfilesApi
import au.org.ala.dataquality.api.QualityServiceRpcApi
import au.org.ala.dataquality.client.ApiClient
import au.org.ala.dataquality.client.auth.ApiKeyAuth
import au.org.ala.dataquality.model.QualityCategory
import au.org.ala.dataquality.model.QualityFilter
import au.org.ala.dataquality.model.QualityProfile
import com.google.common.base.Stopwatch
import com.google.common.cache.Cache
import com.google.common.cache.CacheBuilder
import org.springframework.beans.factory.annotation.Value
import retrofit2.Call
import retrofit2.HttpException

import javax.annotation.PostConstruct

class QualityService {

    def webServicesService

    @Value('${dataquality.enabled}')
    boolean dataQualityEnabled

    @Value('${dataquality.baseUrl}')
    def dataQualityBaseUrl

    @Value('${dataquality.apiKey}')
    String dataQualityAPIKey

    @Value('${dataquality.recordCountCacheSpec}')
    String recordCountCacheSpec

    def grailsApplication

    QualityServiceRpcApi api
    DataProfilesApi dataProfilesApi

    Cache<SpatialSearchRequestParams, Long> recordCountCache

    @PostConstruct
    def init() {
        if (dataQualityEnabled) {
            def apiClient = new ApiClient()
            apiClient.adapterBuilder.baseUrl(dataQualityBaseUrl)
            apiClient.addAuthorization('apiKeyAuth', new ApiKeyAuth('header', 'apiKey'))
            apiClient.setApiKey(dataQualityAPIKey)
            apiClient.okBuilder.addInterceptor { chain ->
                def request = chain.request().newBuilder().addHeader('User-Agent', "${grailsApplication.config.info.app.name}/${grailsApplication.config.info.app.version}").build()
                chain.proceed(request)
            }
            api = apiClient.createService(QualityServiceRpcApi)
            dataProfilesApi = apiClient.createService(DataProfilesApi)
        }
        recordCountCache = CacheBuilder.from(recordCountCacheSpec).build { webServicesService.fullTextSearch(it)?.totalRecords }
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

    List<QualityCategory> findAllEnabledCategories(String profileName) {
        if (dataQualityEnabled) {
            return responseOrThrow(api.findAllEnabledCategories(profileName))
        } else {
            return []
        }
    }

    QualityProfile activeProfile(String profileName = null, String userId = null) {
        if (dataQualityEnabled) {
            return responseOrThrow(api.activeProfile(profileName, userId))
        } else {
            return null
        }
    }

    QualityProfile getProfile(String profileName) {
        if (dataQualityEnabled) {
            return responseOrThrow(dataProfilesApi.dataProfilesId(profileName))
        } else {
            return null
        }
    }

    QualityProfile getDefaultProfile(String userId = null) {
        if (dataQualityEnabled) {
            return responseOrThrow(api.getDefaultProfile(userId))
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

    Map<String, String> getAllInverseCategoryFiltersForProfile(QualityProfile profile) {
        if (dataQualityEnabled) {
            return responseOrThrow(api.getAllInverseCategoryFiltersForProfile(profile.id?.toInteger()))
        } else {
            return [:]
        }
    }

    List<QualityProfile> findAllEnabledProfiles(boolean enabled, String userId = null) {
        if (dataQualityEnabled) {
            return responseOrThrow(dataProfilesApi.dataProfiles(null, null, null, null, enabled, null, null, userId))
        } else {
            return []
        }
    }

    def clearRecordCountCache() {
        recordCountCache.invalidateAll()
    }

    private Long countRecordsExcludedByLabel(List<String> otherLabels, SpatialSearchRequestParams requestParams) {
        def srp = requestParams.clone().with {
            it.pageSize = 0
            it.start = 0
            it.flimit = 0
            it.facet = false
            it.sort = ''
            it.max = 0
            it.offset = 0
            it.disableQualityFilter = otherLabels
            it
        }
        recordCountCache.get(srp)
    }

    Long countTotalRecords(SpatialSearchRequestParams requestParams) {
        if (dataQualityEnabled) {
            def srp = requestParams.clone().with {
                it.pageSize = 0
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
            return recordCountCache.get(srp)
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
                [(it.label): totalRecords - countRecordsExcludedByLabel(otherLabels, requestParams) ]
            }
            log.error("Quality Category facet counts took {}", sw)
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

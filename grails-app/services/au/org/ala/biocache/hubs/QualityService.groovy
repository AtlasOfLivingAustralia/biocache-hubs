package au.org.ala.biocache.hubs

import au.org.ala.dataquality.api.ProfilesApi
import au.org.ala.dataquality.api.QualityServiceRpcApi
import au.org.ala.dataquality.client.ApiClient
import au.org.ala.dataquality.model.QualityCategory
import au.org.ala.dataquality.model.QualityFilter
import au.org.ala.dataquality.model.QualityProfile
import com.google.common.base.Stopwatch
import com.google.common.cache.Cache
import com.google.common.cache.CacheBuilder
import org.springframework.beans.factory.annotation.Value
import retrofit2.Call

import javax.annotation.PostConstruct
import java.util.concurrent.TimeUnit

class QualityService {

    def webServicesService

    @Value('${dataquality.enabled}')
    boolean dataQualityEnabled

    @Value('${dataquality.baseUrl}')
    def dataQualityBaseUrl

    def grailsApplication

    QualityServiceRpcApi api
    ProfilesApi profilesApi

    @PostConstruct
    def init() {
        if (dataQualityEnabled) {
            def apiClient = new ApiClient()
            apiClient.adapterBuilder.baseUrl(dataQualityBaseUrl)
            apiClient.okBuilder.addInterceptor { chain ->
                def request = chain.request().newBuilder().addHeader('User-Agent', "${grailsApplication.config.info.app.name}/${grailsApplication.config.info.app.version}").build()
                chain.proceed(request)
            }
            api = apiClient.createService(QualityServiceRpcApi)
            profilesApi = apiClient.createService(ProfilesApi)
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

    List<QualityCategory> findAllEnabledCategories(String profileName) {
        if (dataQualityEnabled) {
            return responseOrThrow(api.findAllEnabledCategories(profileName))
        } else {
            return []
        }
    }

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

    List<QualityProfile> findAllEnabledProfiles(boolean enabled) {
        if (dataQualityEnabled) {
            return responseOrThrow(profilesApi.profiles(null, null, null, null, enabled, null, null))
        } else {
            return []
        }
    }

    def clearRecordCountCache() {
        recordCountCache.invalidateAll()
    }

    Cache<SpatialSearchRequestParams, Long> recordCountCache = CacheBuilder.newBuilder().expireAfterWrite(1, TimeUnit.DAYS).build { webServicesService.fullTextSearch(it)?.totalRecords }

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
            throw new RuntimeException("Exception executing ${call.request()}, response code: ${response.code()}")
        }
    }
}

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

    @Value('${dataquality.baseUrl}')
    def dataQualityBaseUrl

    def grailsApplication

    QualityServiceRpcApi api
    ProfilesApi profilesApi

    @PostConstruct
    def init() {
        def apiClient = new ApiClient()
        apiClient.adapterBuilder.baseUrl(dataQualityBaseUrl)
        apiClient.okBuilder.addInterceptor { chain ->
            def request = chain.request().newBuilder().addHeader('User-Agent', "${grailsApplication.config.info.app.name}/${grailsApplication.config.info.app.version}").build()
            chain.proceed(request)
        }
        api = apiClient.createService(QualityServiceRpcApi)
        profilesApi = apiClient.createService(ProfilesApi)
    }

    Map<String, String> getEnabledFiltersByLabel(String profileName) {
        return responseOrThrow(api.getEnabledFiltersByLabel(profileName))
    }

    List<String> getEnabledQualityFilters(String profileName) {
        return responseOrThrow(api.getEnabledQualityFilters(profileName))
    }

    Map<String, List<QualityFilter>> getGroupedEnabledFilters(String profileName) {
        return responseOrThrow(api.getGroupedEnabledFilters(profileName))
    }

    List<QualityCategory> findAllEnabledCategories(String profileName) {
        return responseOrThrow(api.findAllEnabledCategories(profileName))
    }

    QualityProfile activeProfile(String profileName) {
        return responseOrThrow(api.activeProfile(profileName))
    }

    String getJoinedQualityFilter(String profileName) {
        return responseOrThrow(api.getJoinedQualityFilter(profileName))
    }

    String getInverseCategoryFilter(QualityCategory category) {
        return responseOrThrow(api.getInverseCategoryFilter(category.id?.toInteger()))
    }

    List<QualityProfile> findAllEnabledProfiles(boolean enabled) {
        return responseOrThrow(profilesApi.profiles(null, null, null, null, enabled, null, null))
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
        recordCountCache.get(srp)
    }

    Map<String, Long> getExcludeCount(List<QualityCategory> qualityCategories, SpatialSearchRequestParams requestParams) {
        Stopwatch sw = Stopwatch.createStarted()

        def totalRecords = countTotalRecords(requestParams)
        def labels = qualityCategories*.label as Set
        def response = qualityCategories.collectEntries {
                    def otherLabels = (labels - it.label) as List
                    [(it.label): totalRecords - countRecordsExcludedByLabel(otherLabels, requestParams) ]
                }
        log.error("Quality Category facet counts took {}", sw)
        return response
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

package au.org.ala.biocache.hubs

import com.google.common.base.Stopwatch
import com.google.common.cache.Cache
import com.google.common.cache.CacheBuilder
import grails.transaction.Transactional

import java.util.concurrent.TimeUnit

@Transactional
class QualityService {

    def webServicesService

    def createOrUpdateCategory(QualityCategory qualityCategory) {
        qualityCategory.save(validate: true, failOnError: true)
    }

    def createOrUpdateFilter(QualityFilter qualityFilter) {
       qualityFilter.save(validate: true, failOnError: true)
    }

    void deleteFilter(Long id) {
        QualityFilter.get(id)?.delete()
    }

    void deleteCategory(QualityCategory qualityCategory) {
        qualityCategory.delete()
    }

    @Transactional(readOnly = true)
    Map<String, String> getEnabledFiltersByLabel() {
        getGroupedEnabledFilters().collectEntries { [(it.key): it.value.join(' AND ')] }
    }

    @Transactional(readOnly = true)
    List<String> getEnabledQualityFilters() {
        QualityFilter.withCriteria {
            eq('enabled', true)
            qualityCategory {
                eq('enabled', true)
            }
            projections {
                property('filter')
            }
//            order('qualityCategory.dateCreated')
            order('dateCreated')
        }
    }

    @Transactional(readOnly = true)
    Map<String, List<String>> getGroupedEnabledFilters() {
        QualityFilter.withCriteria {
            eq('enabled', true)
            qualityCategory {
                eq('enabled', true)
            }
            order('dateCreated')
        }.groupBy { QualityFilter qualityFilter ->
            qualityFilter.qualityCategory.label
        }.collectEntries { label, filters ->
            [ (label): filters*.filter ]
        }
    }

    @Transactional(readOnly = true)
    Map<QualityCategory, List<QualityFilter>> getEnabledCategoriesAndFilters() {
        QualityFilter.withCriteria {
            eq('enabled', true)
            qualityCategory {
                eq('enabled', true)
            }
        }.groupBy {
            (it.qualityCategory)
        }
    }

    @Transactional(readOnly = true)
    Map<QualityCategory, String> getEnabledFiltersByCategory() {
        getEnabledCategoriesAndFilters().collectEntries { [(it.key): it.value.join(' AND ')] }
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

    private Long countTotalRecords(SpatialSearchRequestParams requestParams) {
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

    String getJoinedQualityFilter() {
        enabledQualityFilters.join(' AND ')
    }

    @Transactional(readOnly = true)
    Map<String, Long> getExcludeCount(List<QualityCategory> qualityCategories, SpatialSearchRequestParams requestParams) {
        Stopwatch sw = Stopwatch.createStarted()

        def totalRecords = countTotalRecords(requestParams)
        def labels = qualityCategories*.label as Set
        def response = qualityCategories.collectEntries {
                    def otherLabels = (labels - it.label) as List
                    [(it.id): totalRecords - countRecordsExcludedByLabel(otherLabels, requestParams) ]
                }
        log.error("Quality Category facet counts took {}", sw)
        return response
    }
}

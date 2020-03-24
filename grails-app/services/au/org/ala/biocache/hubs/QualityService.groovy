package au.org.ala.biocache.hubs

import grails.plugin.cache.Cacheable
import grails.transaction.Transactional

@Transactional
class QualityService {

    def webServicesService

    def createOrUpdate(QualityCategory qualityCategory) {
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

    @Cacheable('shortTermCache')
    Long countRecordsExcludedByLabel(String label) {
        def labels = QualityCategory.withCriteria {
            ne('label', label)
            eq('enabled', true)
            projections {
                property('label')
            }
        }
        def srp = new SpatialSearchRequestParams().with {
            it.q = '*:*'
            it.pageSize = 0
            it.start = 0
            it.flimit = 999
            it.disableQualityFilter = labels
            it
        }
        def results = webServicesService.fullTextSearch(srp)
        countTotalRecords() - results.totalRecords
    }

    @Cacheable('shortTermCache')
    Long countTotalRecords() {
        def srp = new SpatialSearchRequestParams().with {
            it.q = '*:*'
            it.pageSize = 0
            it.start = 0
            it.flimit = 999
            it.disableAllQualityFilters = true
            it
        }
        def results = webServicesService.fullTextSearch(srp)
        results.totalRecords
    }

    String getJoinedQualityFilter() {
        enabledQualityFilters.join(' AND ')
    }
}

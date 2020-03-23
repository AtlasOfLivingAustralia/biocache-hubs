package au.org.ala.biocache.hubs

import grails.transaction.Transactional

@Transactional
class QualityService {

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

    String getJoinedQualityFilter() {
        enabledQualityFilters.join(' AND ')
    }
}

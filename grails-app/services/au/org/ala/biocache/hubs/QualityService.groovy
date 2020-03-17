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
    def qualityFilter() {
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
        }.join(' AND ')
    }
}

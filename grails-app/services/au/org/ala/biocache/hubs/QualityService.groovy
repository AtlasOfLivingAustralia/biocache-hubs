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
        QualityCategory.findAllByEnabled(true).findAll { it.enabled }*.qualityFilters.collect {
            def categoryFilter = it.findAll { it.enabled }*.filter.join(' AND ')
            categoryFilter // ? "( $categoryFilter )" : ''
        }.findAll().join(' AND ')
    }
}

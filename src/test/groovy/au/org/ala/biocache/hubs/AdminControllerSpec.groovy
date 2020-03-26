package au.org.ala.biocache.hubs;

import grails.test.mixin.Mock
import grails.test.mixin.TestFor
import grails.validation.ValidationErrors
import grails.validation.ValidationException
import spock.lang.Specification

@TestFor(AdminController)
@Mock([QualityCategory, QualityFilter])
class AdminControllerSpec extends Specification {

    def setup() {
        controller.qualityService = Mock(QualityService)
    }

    def 'test dataQualityFilters'() {
        setup:
        QualityCategory qc1 = new QualityCategory(name: 'name', label: 'label', description: 'description').save(flush: true)
        QualityCategory qc2 = new QualityCategory(name: 'name2', label: 'label2', description: 'description').save(flush: true)

        when:
        controller.dataQualityFilters()

        then:
        1 * controller.qualityService.enabledFiltersByLabel >> [label: '', label2: '']
        model.qualityCategoryList == [qc1, qc2]
        model.qualityFilterStrings == [label: '', label2: '']
    }

    def 'test saveQualityCategory'() {
        setup:
        QualityCategory qc1 = new QualityCategory(name: 'name', label: 'label', description: 'description')

        when:
        controller.saveQualityCategory(qc1)

        then:
        1 * controller.qualityService.createOrUpdateCategory(qc1) >> qc1
        response.redirectedUrl == '/admin/dataQualityFilters'
    }

    def 'test saveQualityCategory failure'() {
        setup:
        QualityCategory qc1 = new QualityCategory(name: 'name', label: 'label', description: 'description')
        ValidationErrors ve = new ValidationErrors(qc1, 'qualityCategory')

        when:
        controller.saveQualityCategory(qc1)

        then:
        1 * controller.qualityService.createOrUpdateCategory(qc1) >> { throw new ValidationException('msg', ve) }
        flash.errors == ve
        response.redirectedUrl == '/admin/dataQualityFilters'
    }

    def 'test enableQualityCategory'() {
        setup:
        QualityCategory qc1 = new QualityCategory(name: 'name', label: 'label', description: 'description', enabled: true).save(flush: true)
        request.addParameter('id', "${qc1.id}")
        request.addParameter('enabled', "false")

        when:
        controller.enableQualityCategory()

        then:
        qc1.enabled == false
        response.redirectedUrl == '/admin/dataQualityFilters'

    }

    def 'test deleteQualityCategory'() {
        setup:
        QualityCategory qc1 = new QualityCategory(name: 'name', label: 'label', description: 'description', enabled: true).save(flush: true)

        when:
        controller.deleteQualityCategory(qc1)

        then:
        1 * controller.qualityService.deleteCategory(qc1)
        response.redirectedUrl == '/admin/dataQualityFilters'
    }

    def 'test saveQualityFilter'() {
        setup:
        QualityCategory qc1 = new QualityCategory(name: 'name', label: 'label', description: 'description').save(flush: true)
        QualityFilter qf1 = new QualityFilter(description: 'desc', filter: 'filter', qualityCategory: qc1)

        when:
        controller.saveQualityFilter(qf1)

        then:
        1 * controller.qualityService.createOrUpdateFilter(qf1) >> qf1
        response.redirectedUrl == '/admin/dataQualityFilters'
    }

    def 'test saveQualityFilter failure'() {
        setup:
        QualityCategory qc1 = new QualityCategory(name: 'name', label: 'label', description: 'description').save(flush: true)
        QualityFilter qf1 = new QualityFilter(description: 'desc', filter: 'filter', qualityCategory: qc1)
        ValidationErrors ve = new ValidationErrors(qf1, 'qualityFilter')

        when:
        controller.saveQualityFilter(qf1)

        then:
        1 * controller.qualityService.createOrUpdateFilter(qf1) >> { throw new ValidationException('msg', ve) }
        flash.errors == ve
        response.redirectedUrl == '/admin/dataQualityFilters'
    }

    def 'test saveQualityFilter failure 2'() {
        setup:
        QualityCategory qc1 = new QualityCategory(name: 'name', label: 'label', description: 'description').save(flush: true)
        QualityFilter qf1 = new QualityFilter(description: 'desc', filter: 'filter', qualityCategory: qc1)
        ValidationErrors ve = new ValidationErrors(qc1, 'qualityCategory')

        when:
        controller.saveQualityFilter(qf1)

        then:
        1 * controller.qualityService.createOrUpdateFilter(qf1) >> { throw new IllegalStateException('msg') }
        response.status == 400
    }

    def 'test deleteQualityFilter'() {
        setup:
        QualityCategory qc1 = new QualityCategory(name: 'name', label: 'label', description: 'description', enabled: true).save(flush: true)
        QualityFilter qf1 = new QualityFilter(description: 'desc', filter: 'filter', qualityCategory: qc1).save(flush: true)
        request.addParameter('id', "${qf1.id}")

        when:
        controller.deleteQualityFilter()

        then:
        1 * controller.qualityService.deleteFilter(qf1.id)
        response.redirectedUrl == '/admin/dataQualityFilters'
    }

    def 'test enableQualityFilter'() {
        setup:
        QualityCategory qc1 = new QualityCategory(name: 'name', label: 'label', description: 'description', enabled: true).save(flush: true)
        QualityFilter qf1 = new QualityFilter(description: 'desc', filter: 'filter', enabled: true, qualityCategory: qc1).save(flush: true)
        request.addParameter('id', "${qf1.id}")
        request.addParameter('enabled', "false")

        when:
        controller.enableQualityFilter()

        then:
        qf1.enabled == false
        response.redirectedUrl == '/admin/dataQualityFilters'
    }

}

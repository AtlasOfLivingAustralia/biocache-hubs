package au.org.ala.biocache.hubs

import grails.test.mixin.Mock
import grails.test.mixin.TestFor
import grails.validation.ValidationException
import spock.lang.Specification

@TestFor(QualityService)
@Mock([QualityCategory, QualityFilter])
class QualityServiceSpec extends Specification {

    def 'test create'() {
        setup:
        QualityCategory qc = new QualityCategory(name: 'name', label: 'label', description: 'description')

        when:
        def result = service.createOrUpdateCategory(qc)

        then:
        result != null
        result.id != null
        result.name == 'name'
        result.label == 'label'
        result.description == 'description'
        result.enabled == true
    }

    def 'test update'() {
        setup:
        QualityCategory qc = new QualityCategory(name: 'name', label: 'label', description: '').save()

        when:
        qc.description = 'description'
        def result = service.createOrUpdateCategory(qc)

        then:
        result.description == 'description'
    }

    def 'test invalid create'(name, label) {
        setup:
        QualityCategory qc = new QualityCategory(name: name, label: label, description: 'desc')

        when:
        def result = service.createOrUpdateCategory(qc)

        then:
        thrown ValidationException

        where:
        name || label
        'name' | null
        null | 'label'
    }

    def 'test filter create'() {
        setup:
        QualityCategory qc = new QualityCategory(name: 'name', label: 'label').save()
        QualityFilter qf = new QualityFilter(qualityCategory: qc, filter: 'asdf', description: 'asdf')

        when:
        def result = service.createOrUpdateFilter(qf)

        then:
        result != null
        qf.filter == 'asdf'
        qf.description == 'asdf'

        when:
        result.filter = 'qwerty'
        result = service.createOrUpdateFilter(result)

        then:
        result != null
        result.filter == 'qwerty'
    }

    def 'test getEnabledCategoriesAndFilters'() {
        setup:
        QualityCategory qc1 = new QualityCategory(name: 'name', label: 'label', description: 'desc', enabled: true).save(flush: true, failOnError: true)
        QualityFilter qf11 = new QualityFilter(description: 'label11', filter: 'filter11', enabled: true, qualityCategory: qc1).save(flush: true, failOnError: true)
        QualityFilter qf12 = new QualityFilter(description: 'label12', filter: 'filter12', enabled: false, qualityCategory: qc1).save(flush: true, failOnError: true)
        QualityCategory qc2 = new QualityCategory(name: 'name2', label: 'label2', description: 'desc2', enabled: false).save(flush: true, failOnError: true)
        QualityFilter qf21 = new QualityFilter(description: 'label21', filter: 'filter21', enabled: true, qualityCategory: qc2).save(flush: true, failOnError: true)
        QualityFilter qf22 = new QualityFilter(description: 'label22', filter: 'filter22', enabled: false, qualityCategory: qc2).save(flush: true, failOnError: true)

        when:
        def result = service.getEnabledCategoriesAndFilters()

        then:
        result == [(qc1): [qf11]]
    }

    def 'test getEnabledQualityFilters'() {
        setup:
        QualityCategory qc1 = new QualityCategory(name: 'name', label: 'label', description: 'desc', enabled: true).save(flush: true, failOnError: true)
        QualityFilter qf11 = new QualityFilter(description: 'label11', filter: 'filter11', enabled: true, qualityCategory: qc1).save(flush: true, failOnError: true)
        QualityFilter qf12 = new QualityFilter(description: 'label12', filter: 'filter12', enabled: false, qualityCategory: qc1).save(flush: true, failOnError: true)
        QualityCategory qc2 = new QualityCategory(name: 'name2', label: 'label2', description: 'desc2', enabled: false).save(flush: true, failOnError: true)
        QualityFilter qf21 = new QualityFilter(description: 'label21', filter: 'filter21', enabled: true, qualityCategory: qc2).save(flush: true, failOnError: true)
        QualityFilter qf22 = new QualityFilter(description: 'label22', filter: 'filter22', enabled: false, qualityCategory: qc2).save(flush: true, failOnError: true)

        when:
        def result = service.getEnabledQualityFilters()

        then:
        result == [qf11.filter]
    }

    def 'test getGroupedEnabledFilters'() {
        setup:
        QualityCategory qc1 = new QualityCategory(name: 'name', label: 'label', description: 'desc', enabled: true).save(flush: true, failOnError: true)
        QualityFilter qf11 = new QualityFilter(description: 'label11', filter: 'filter11', enabled: true, qualityCategory: qc1).save(flush: true, failOnError: true)
        QualityFilter qf12 = new QualityFilter(description: 'label12', filter: 'filter12', enabled: false, qualityCategory: qc1).save(flush: true, failOnError: true)
        QualityCategory qc2 = new QualityCategory(name: 'name2', label: 'label2', description: 'desc2', enabled: false).save(flush: true, failOnError: true)
        QualityFilter qf21 = new QualityFilter(description: 'label21', filter: 'filter21', enabled: true, qualityCategory: qc2).save(flush: true, failOnError: true)
        QualityFilter qf22 = new QualityFilter(description: 'label22', filter: 'filter22', enabled: false, qualityCategory: qc2).save(flush: true, failOnError: true)

        when:
        def result = service.getGroupedEnabledFilters()

        then:
        result == [(qc1.label): [qf11.filter]]
    }

    def 'test getJoinedQualityFilter'() {
        setup:
        QualityCategory qc1 = new QualityCategory(name: 'name', label: 'label', description: 'desc', enabled: true).save(flush: true, failOnError: true)
        QualityFilter qf11 = new QualityFilter(description: 'label11', filter: 'filter11', enabled: true, qualityCategory: qc1).save(flush: true, failOnError: true)
        QualityFilter qf12 = new QualityFilter(description: 'label12', filter: 'filter12', enabled: false, qualityCategory: qc1).save(flush: true, failOnError: true)
        QualityCategory qc2 = new QualityCategory(name: 'name2', label: 'label2', description: 'desc2', enabled: false).save(flush: true, failOnError: true)
        QualityFilter qf21 = new QualityFilter(description: 'label21', filter: 'filter21', enabled: true, qualityCategory: qc2).save(flush: true, failOnError: true)
        QualityFilter qf22 = new QualityFilter(description: 'label22', filter: 'filter22', enabled: false, qualityCategory: qc2).save(flush: true, failOnError: true)
        QualityCategory qc3 = new QualityCategory(name: 'name3', label: 'label3', description: 'desc3', enabled: true).save(flush: true, failOnError: true)
        QualityFilter qf31 = new QualityFilter(description: 'label31', filter: 'filter31', enabled: false, qualityCategory: qc3).save(flush: true, failOnError: true)
        QualityFilter qf32 = new QualityFilter(description: 'label32', filter: 'filter32', enabled: true, qualityCategory: qc3).save(flush: true, failOnError: true)

        when:
        def result = service.joinedQualityFilter

        then:
        result == "${qf11.filter} AND ${qf32.filter}"
    }

    def 'test inverse filter'() {
        setup:
        QualityCategory qc1 = new QualityCategory(name: 'name', label: 'label', description: 'desc', enabled: true).save(flush: true, failOnError: true)
        QualityFilter qf11 = new QualityFilter(description: 'label11', filter: 'a:b', enabled: true, qualityCategory: qc1).save(flush: true, failOnError: true)
        QualityFilter qf12 = new QualityFilter(description: 'label12', filter: 'b:a', enabled: true, qualityCategory: qc1).save(flush: true, failOnError: true)
        // not enabled
        QualityFilter qf13 = new QualityFilter(description: 'label12', filter: 'z:y', enabled: false, qualityCategory: qc1).save(flush: true, failOnError: true)

        QualityCategory qc2 = new QualityCategory(name: 'name2', label: 'label2', description: 'desc2', enabled: true).save(flush: true, failOnError: true)
        QualityFilter qf21 = new QualityFilter(description: 'label21', filter: 'c:[0 TO 1]', enabled: true, qualityCategory: qc2).save(flush: true, failOnError: true)
        QualityFilter qf22 = new QualityFilter(description: 'label22', filter: '-d:e', enabled: true, qualityCategory: qc2).save(flush: true, failOnError: true)
        QualityFilter qf23 = new QualityFilter(description: 'label23', filter: '-e:f', enabled: true, qualityCategory: qc2).save(flush: true, failOnError: true)

        QualityCategory qc3 = new QualityCategory(name: 'name3', label: 'label3', description: 'desc3', enabled: true).save(flush: true, failOnError: true)
        QualityFilter qf31 = new QualityFilter(description: 'label31', filter: '-f:g', enabled: true, qualityCategory: qc3).save(flush: true, failOnError: true)

        QualityCategory qc4 = new QualityCategory(name: 'name4', label: 'label4', description: 'desc4', enabled: true).save(flush: true, failOnError: true)
        QualityFilter qf41 = new QualityFilter(description: 'label41', filter: '+f:g', enabled: true, qualityCategory: qc4).save(flush: true, failOnError: true)

        QualityCategory qc5 = new QualityCategory(name: 'name5', label: 'label5', description: 'desc5', enabled: true).save(flush: true, failOnError: true)
        QualityFilter qf51 = new QualityFilter(description: 'label51', filter: 'f:g', enabled: true, qualityCategory: qc5).save(flush: true, failOnError: true)

        QualityCategory qc7 = new QualityCategory(name: 'name7', label: 'label7', description: 'desc7', enabled: true).save(flush: true, failOnError: true)
        QualityFilter qf71 = new QualityFilter(description: 'label71', filter: '-c:[0 TO 1]', enabled: true, qualityCategory: qc7).save(flush: true, failOnError: true)
        QualityFilter qf72 = new QualityFilter(description: 'label72', filter: 'd:e', enabled: true, qualityCategory: qc7).save(flush: true, failOnError: true)
        QualityFilter qf73 = new QualityFilter(description: 'label73', filter: 'e:f', enabled: true, qualityCategory: qc7).save(flush: true, failOnError: true)


        when:
        // inverse a:b AND b:a
        def result = service.getInverseCategoryFilter(qc1)

        then:
        result == '-a:b -b:a'

        when:
        // inverse c:[0 TO 1] AND -d:e AND -e:f
        result = service.getInverseCategoryFilter(qc2)

        then:
        result == '-(-d:e -e:f AND c:[0 TO 1])'
//        result == '-(+c:[0 TO 1] -d:e -e:f)'

        when:
        result = service.getInverseCategoryFilter(qc3)

        then:
        result == 'f:g'

        when:
        result = service.getInverseCategoryFilter(qc4)

        then:
        result == '-f:g'

        when:
        result = service.getInverseCategoryFilter(qc5)

        then:
        result == '-f:g'

        when:
        result = service.getInverseCategoryFilter(qc7)

        then:
        result == 'c:[0 TO 1] -d:e -e:f'

    }

}

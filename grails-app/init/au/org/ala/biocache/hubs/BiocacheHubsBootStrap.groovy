package au.org.ala.biocache.hubs

import grails.converters.JSON

class BiocacheHubsBootStrap {
    def init = { servletContext ->
        QualityProfile.withTransaction {
            def qp = QualityProfile.first()
            if (!qp) {
                qp = new QualityProfile(name: 'Default', shortName: 'default', description: 'This is the default profile, it should be edited', contactName: 'Support Email', contactEmail: '', isDefault: true, enabled: true)
                def qcs = QualityCategory.findAll()
                qcs.each { qp.addToCategories(it) }
                qp.save()
            }
        }

        JSON.registerObjectMarshaller(QualityProfile) {
            def output = [:]
            output['name'] = it.name
            output['shortName'] = it.shortName
            output['description'] = it.description
            output['contactName'] = it.contactName
            output['contactEmail'] = it.contactEmail
            output['categories'] = it.categories
            return output;
        }

        JSON.registerObjectMarshaller(QualityCategory) {
            def output = [:]
            output['enabled'] = it.enabled
            output['name'] = it.name
            output['label'] = it.label
            output['description'] = it.description
            output['qualityFilters'] = it.qualityFilters
            return output;
        }

        JSON.registerObjectMarshaller(QualityFilter) {
            def output = [:]
            output['enabled'] = it.enabled
            output['description'] = it.description
            output['filter'] = it.filter
            return output;
        }
    }
    def destroy = {
    }
}

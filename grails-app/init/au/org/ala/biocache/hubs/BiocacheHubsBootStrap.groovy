package au.org.ala.biocache.hubs

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

    }
    def destroy = {
    }
}

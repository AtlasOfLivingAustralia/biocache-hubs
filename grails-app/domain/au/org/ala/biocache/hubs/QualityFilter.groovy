package au.org.ala.biocache.hubs

class QualityFilter {

    Long id

    String description
    String filter

    Date dateCreated
    Date lastUpdated

    static belongsTo = [ qualityCategory: QualityCategory ]

    static transients = ['filterQueryPart']

    static constraints = {
    }

    static mapping = {
        sort 'dateCreated'
    }

    String getFilterQueryPart() {
        return filter
    }

}

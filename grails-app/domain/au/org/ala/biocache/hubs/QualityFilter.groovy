package au.org.ala.biocache.hubs

class QualityFilter {

    Long id

    boolean enabled = true

    String description
    String filter

    Date dateCreated
    Date lastUpdated

    static belongsTo = [ qualityCategory: QualityCategory ]

    static transients = ['filterQueryPart']

    static constraints = {
    }

    static mapping = {
        enabled defaultValue: 'true'
        sort 'dateCreated'
    }

    String getFilterQueryPart() {
        return filter
    }

}

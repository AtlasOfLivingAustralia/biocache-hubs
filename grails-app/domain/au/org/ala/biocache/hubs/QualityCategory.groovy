package au.org.ala.biocache.hubs

class QualityCategory {

    Long id

    String name
    String label
    String description

    Date dateCreated
    Date lastUpdated

    static hasMany = [ qualityFilters: QualityFilter ]

    static constraints = {
        name unique: true
        label unique: true
        description blank: true, nullable: true
    }

    static mapping = {
        name type: 'text'
        label type: 'text'
        description type: 'text'
        qualityFilters sort: 'dateCreated'
    }
}

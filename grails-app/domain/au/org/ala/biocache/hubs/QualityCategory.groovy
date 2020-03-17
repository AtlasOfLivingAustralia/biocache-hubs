package au.org.ala.biocache.hubs

import groovy.transform.EqualsAndHashCode
import groovy.transform.ToString

@EqualsAndHashCode(includes = ['enabled', 'name', 'label', 'description'])
@ToString(includes = ['enabled', 'name', 'label', 'description'])
class QualityCategory {

    Long id

    boolean enabled = true

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
        enabled defaultValue: 'true'
        name type: 'text'
        label type: 'text'
        description type: 'text'
        qualityFilters sort: 'dateCreated'
        sort 'dateCreated'
    }
}

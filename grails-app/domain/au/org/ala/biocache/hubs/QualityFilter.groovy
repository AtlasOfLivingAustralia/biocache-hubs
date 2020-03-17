package au.org.ala.biocache.hubs

import groovy.transform.EqualsAndHashCode
import groovy.transform.ToString

@EqualsAndHashCode(includes = ['enabled', 'description', 'filter'])
@ToString(includes = ['enabled', 'description', 'filter'])
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

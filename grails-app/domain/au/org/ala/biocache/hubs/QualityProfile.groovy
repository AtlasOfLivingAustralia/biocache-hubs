package au.org.ala.biocache.hubs

import groovy.transform.EqualsAndHashCode
import groovy.transform.ToString

@EqualsAndHashCode(includes = ['name', 'shortName'])
@ToString(includes = ['enabled', 'name', 'shortName', 'isDefault'])
class QualityProfile {

    Long id

    String name
    String shortName

    boolean enabled
    boolean isDefault

    Date dateCreated
    Date lastUpdated

    static hasMany = [categories: QualityCategory]

    static constraints = {
        name unique: true
        shortName unique: true
    }

    static mapping = {
        name type: 'text'
        shortName type: 'text'
        enabled defaultValue: 'true', index: 'quality_profile_enabled_idx'
    }
}

package au.org.ala.biocache.hubs

import com.google.common.base.Stopwatch
import com.google.common.cache.Cache
import com.google.common.cache.CacheBuilder
import grails.core.GrailsApplication
import grails.plugin.cache.Cacheable
import grails.transaction.NotTransactional
import grails.transaction.Transactional
import org.apache.lucene.queryparser.flexible.precedence.PrecedenceQueryParser
import org.apache.lucene.search.BooleanClause
import org.apache.lucene.search.BooleanQuery
import org.apache.lucene.search.Query
import org.apache.lucene.search.TermQuery
import org.apache.lucene.search.TermRangeQuery
import org.grails.web.json.JSONArray
import org.springframework.context.MessageSource
import org.springframework.web.util.UriComponentsBuilder

import java.util.concurrent.TimeUnit

@Transactional
class QualityService {

    GrailsApplication grailsApplication
    MessageSource messageSource
    def webServicesService

    def createOrUpdateCategory(QualityCategory qualityCategory) {
        qualityCategory.save(validate: true, failOnError: true)
    }

    def createOrUpdateFilter(QualityFilter qualityFilter) {
       qualityFilter.save(validate: true, failOnError: true)
    }

    void deleteFilter(Long id) {
        QualityFilter.get(id)?.delete()
    }

    void deleteCategory(QualityCategory qualityCategory) {
        qualityCategory.delete()
    }

    @Transactional(readOnly = true)
    Map<String, String> getEnabledFiltersByLabel(String profileName) {
        getGroupedEnabledFilters(profileName).collectEntries { [(it.key): it.value*.filter.join(' AND ')] }
    }

    @Transactional(readOnly = true)
    List<String> getEnabledQualityFilters(String profileName) {
        QualityProfile qp = activeProfile(profileName)
        QualityFilter.withCriteria {
            eq('enabled', true)
            qualityCategory {
                qualityProfile {
                    eq('id', qp.id)
                }
                eq('enabled', true)
            }
            projections {
                property('filter')
            }
//            order('qualityCategory.dateCreated')
            order('dateCreated')
        }
    }

    @Transactional(readOnly = true)
    Map<String, List<QualityFilter>> getGroupedEnabledFilters(String profileName) {
        QualityProfile qp = activeProfile(profileName)

        QualityFilter.withCriteria {
            eq('enabled', true)
            qualityCategory {
                qualityProfile {
                    eq('id', qp.id)
                }
                eq('enabled', true)
            }
            order('dateCreated')
        }.groupBy { QualityFilter qualityFilter ->
            qualityFilter.qualityCategory.label
        }.collectEntries { label, filters ->
            [ (label): filters ]
        }
    }

    @Transactional(readOnly = true)
    Map<QualityCategory, List<QualityFilter>> getEnabledCategoriesAndFilters(String profileName) {
        QualityProfile qp = activeProfile(profileName)
        QualityFilter.withCriteria {
            eq('enabled', true)
            qualityCategory {
                qualityProfile {
                    eq('id', qp.id)
                }
                eq('enabled', true)
            }
        }.groupBy {
            (it.qualityCategory)
        }
    }

    @Transactional(readOnly = true)
    List<QualityCategory> findAllEnabledCategories(String profileName) {
        QualityProfile qp = activeProfile(profileName)
        QualityCategory.findAllByQualityProfileAndEnabled(qp, true).findAll { category -> category.qualityFilters?.findAll { it.enabled }?.size() > 0 }
    }

    QualityProfile activeProfile(String profileName) {
        QualityProfile qp
        if (profileName) {
            qp = QualityProfile.findByShortName(profileName)
            if (!qp) {
                qp = getDefaultProfile()
            }
        } else {
            qp = getDefaultProfile()
        }
        return qp
    }

    QualityProfile getDefaultProfile() {
        QualityProfile.findByIsDefault(true)
    }

    def clearRecordCountCache() {
        recordCountCache.invalidateAll()
    }

    Cache<SpatialSearchRequestParams, Long> recordCountCache = CacheBuilder.newBuilder().expireAfterWrite(1, TimeUnit.DAYS).build { webServicesService.fullTextSearch(it)?.totalRecords }

    private Long countRecordsExcludedByLabel(List<String> otherLabels, SpatialSearchRequestParams requestParams) {
        def srp = requestParams.clone().with {
            it.pageSize = 0
            it.start = 0
            it.flimit = 0
            it.facet = false
            it.sort = ''
            it.max = 0
            it.offset = 0
            it.disableQualityFilter = otherLabels
            it
        }
        recordCountCache.get(srp)
    }

    public Long countTotalRecords(SpatialSearchRequestParams requestParams) {
        def srp = requestParams.clone().with {
            it.pageSize = 0
            it.start = 0
            it.flimit = 0
            it.facet = false
            it.sort = ''
            it.max = 0
            it.offset = 0
            it.disableQualityFilter = []
            it.disableAllQualityFilters = true
            it
        }
        recordCountCache.get(srp)
    }

    String getJoinedQualityFilter(String profileName) {
        getEnabledQualityFilters(profileName).join(' AND ')
    }

    @Transactional(readOnly = true)
    Map<String, Long> getExcludeCount(List<QualityCategory> qualityCategories, SpatialSearchRequestParams requestParams) {
        Stopwatch sw = Stopwatch.createStarted()

        def totalRecords = countTotalRecords(requestParams)
        def labels = qualityCategories*.label as Set
        def response = qualityCategories.collectEntries {
                    def otherLabels = (labels - it.label) as List
                    [(it.label): totalRecords - countRecordsExcludedByLabel(otherLabels, requestParams) ]
                }
        log.error("Quality Category facet counts took {}", sw)
        return response
    }

    @Transactional(readOnly = true)
    String getInverseCategoryFilter(QualityCategory category) {
        PrecedenceQueryParser qp = new PrecedenceQueryParser()
        TermQuery
        def filters = category.qualityFilters.findAll { it.enabled }*.filter
        def filter = filters.join(' AND ')
        if (!filter) return ''
        Query query = qp.parse(filter, '')
        String inverseQuery
        switch (query) {
            case BooleanQuery:
                inverseQuery = inverseBooleanQuery(query, filter)
                break
            default:
                inverseQuery = inverseOtherQuery(query)
                break
        }

        return inverseQuery
    }

    private def inverseOtherQuery(Query query) {
        return new BooleanQuery.Builder().add(query, BooleanClause.Occur.MUST_NOT).build().toString()
    }

    private def inverseBooleanQuery(BooleanQuery booleanQuery, String originalQuery) {
        def clauses = booleanQuery.clauses()
        if ( clauses.size() == 1) {
            def first = clauses.first()
            if (first.prohibited) {
                return first.query.toString()
            } else {
                return inverseOtherQuery(first.query)
            }
        }

        // SOLR will return different results for:
        // 1) geospatial_kosher:"false" assertions:"habitatMismatch" -coordinate_uncertainty:[0+TO+10000]
        // 2) geospatial_kosher:"false" OR assertions:"habitatMismatch" OR -coordinate_uncertainty:[0+TO+10000]
        // 3) -(-geospatial_kosher:"false" -assertions:"habitatMismatch" +coordinate_uncertainty:[0+TO+10000])
        // 4) -(-geospatial_kosher:"false" AND -assertions:"habitatMismatch" AND coordinate_uncertainty:[0+TO+10000])
        //
        // 4) gives the correct results for inverting
        // -geospatial_kosher:"false" AND -assertions:"habitatMismatch" AND coordinate_uncertainty:[0+TO+10000]
        // so if the boolean contains a should or must range query then we just wrap the original query in an exclude
        if (clauses.any { clause -> clause.query instanceof TermRangeQuery && clause.occur != BooleanClause.Occur.MUST_NOT }) {
            return "-(${originalQuery})"
        } else {
            def bqb = new BooleanQuery.Builder()
            clauses.each { clause ->
                bqb.add(clause.query, clause.prohibited ? BooleanClause.Occur.SHOULD : BooleanClause.Occur.MUST_NOT)
            }
            return bqb.build().toString()
        }
    }

    @Transactional
    void createOrUpdateProfile(QualityProfile qualityProfile) {
        qualityProfile.save(validate: true, failOnError: true)
    }

    @Transactional
    void setDefaultProfile(Long id) {
        def qp = QualityProfile.get(id)
        if (qp) {
            qp.isDefault = true
            qp.save()
            def others = QualityProfile.findAllByIdNotEqual(id)
            others.each { it.isDefault = false }
            QualityProfile.saveAll(others)
        }
    }

    @Transactional
    void deleteProfile(QualityProfile qualityProfile) {
        qualityProfile.delete()
    }

    @NotTransactional
    String getFieldDescription(boolean include, String field, String value, Locale locale) {
        def cleanedValue = dequote(value)
        boolean isAssertion = field == 'assertions'
        def result

        def description
        if (isAssertion) {
            def assertionsMap = webServicesService.getAssertionCodeMap()
            description = assertionsMap[dequote(cleanedValue)]?.description
        }
        if (!description) {
            def biocacheField = getBiocacheField(field)
            description = biocacheField?.description
        }
        if (!description) {
            def props = webServicesService.getMessagesPropertiesFile()
            description = props["$field.$cleanedValue"] ?: props[cleanedValue] ?: props[field]
        }

        if (description && isAssertion) {
            if (include) {
                result = messageSource.getMessage('field.description.assertion.include', [description].toArray(), 'Include only records where {0}', locale)
            } else {
                result = messageSource.getMessage('field.description.assertion.exclude', [description].toArray(), 'Exclude all records where {0}', locale)
            }
        } else if (description) {
            if (include) {
                result = messageSource.getMessage('field.description.include', [description, value].toArray(), 'Include only records where {0} is "{1}"', locale)
            } else {
                result = messageSource.getMessage('field.description.exclude', [description, value].toArray(), 'Exclude all records where {0} is "{1}"', locale)
            }
        }

        return result
    }

    private String dequote(String string) {
        String retVal
        if (string == '"') {
            retVal = string
        } else if (string.startsWith('"') && string.endsWith('"')) {
            retVal = string.substring(1, string.length() - 1)
        } else {
            retVal = string
        }
        return retVal
    }

    /**
     * Get fields info from http://biocache.ala.org.au/ws/index/fields.
     * Example record:
     *
     * {
     *   dwcTerm: "basisOfRecord",
     *   downloadDescription: "Basis Of Record - processed",
     *   indexed: true,
     *   stored: true,
     *   downloadName: "basisOfRecord.p",
     *   multivalue: false,
     *   classs: "Record",
     *   description: "Basis Of Record - processed",
     *   dataType: "string",
     *   name: "basis_of_record"
     * }
     *
     * @return fields (List)
     */
    @Cacheable('longTermCache')
    List getBiocacheFields()  {
        List fields
        def url = grailsApplication.config.getProperty('biocache.indexedFieldsUrl', String)
        def resp = webServicesService.getJsonElements(url)

        resp
    }

    /**
     * Get field info from http://biocache.ala.org.au/ws/index/fields?fl=<field>.
     * Example record:
     *
     * {
     *   dwcTerm: "basisOfRecord",
     *   downloadDescription: "Basis Of Record - processed",
     *   indexed: true,
     *   stored: true,
     *   downloadName: "basisOfRecord.p",
     *   multivalue: false,
     *   classs: "Record",
     *   description: "Basis Of Record - processed",
     *   dataType: "string",
     *   name: "basis_of_record"
     * }
     *
     */
    def getBiocacheField(String field) {
        def baseUrl = grailsApplication.config.getProperty('biocache.indexedFieldsUrl', String)
        def url = UriComponentsBuilder.fromUriString(baseUrl).queryParam('fl', field).toUriString()
        def resp = webServicesService.getJsonElements(url)
        if (resp instanceof JSONArray && resp.length() > 0) resp = resp[0]
        resp
    }
}

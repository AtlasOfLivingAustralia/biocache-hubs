package au.org.ala.biocache.hubs

import com.google.common.base.Stopwatch
import com.google.common.cache.Cache
import com.google.common.cache.CacheBuilder
import grails.transaction.Transactional
import org.apache.lucene.analysis.Analyzer
import org.apache.lucene.analysis.DelegatingAnalyzerWrapper
import org.apache.lucene.analysis.TokenStream
import org.apache.lucene.analysis.standard.StandardAnalyzer
import org.apache.lucene.queryparser.flexible.precedence.PrecedenceQueryParser
import org.apache.lucene.queryparser.flexible.standard.StandardQueryParser
import org.apache.lucene.search.BooleanClause
import org.apache.lucene.search.BooleanQuery
import org.apache.lucene.search.Query
import org.apache.lucene.search.TermQuery
import org.apache.lucene.search.TermRangeQuery

import java.util.concurrent.TimeUnit

@Transactional
class QualityService {

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
    Map<String, String> getEnabledFiltersByLabel() {
        getGroupedEnabledFilters().collectEntries { [(it.key): it.value.join(' AND ')] }
    }

    @Transactional(readOnly = true)
    List<String> getEnabledQualityFilters() {
        QualityFilter.withCriteria {
            eq('enabled', true)
            qualityCategory {
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
    Map<String, List<String>> getGroupedEnabledFilters() {
        QualityFilter.withCriteria {
            eq('enabled', true)
            qualityCategory {
                eq('enabled', true)
            }
            order('dateCreated')
        }.groupBy { QualityFilter qualityFilter ->
            qualityFilter.qualityCategory.label
        }.collectEntries { label, filters ->
            [ (label): filters*.filter ]
        }
    }

    @Transactional(readOnly = true)
    Map<QualityCategory, List<QualityFilter>> getEnabledCategoriesAndFilters() {
        QualityFilter.withCriteria {
            eq('enabled', true)
            qualityCategory {
                eq('enabled', true)
            }
        }.groupBy {
            (it.qualityCategory)
        }
    }

    @Transactional(readOnly = true)
    Map<QualityCategory, String> getEnabledFiltersByCategory() {
        getEnabledCategoriesAndFilters().collectEntries { [(it.key): it.value.join(' AND ')] }
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

    private Long countTotalRecords(SpatialSearchRequestParams requestParams) {
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

    String getJoinedQualityFilter() {
        enabledQualityFilters.join(' AND ')
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
}

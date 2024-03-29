package au.org.ala.biocache.hubs

import grails.util.Holders
import grails.validation.Validateable
import groovy.transform.AutoClone
import groovy.transform.EqualsAndHashCode
import groovy.util.logging.Slf4j
import org.apache.commons.httpclient.URIException
import org.apache.commons.httpclient.util.URIUtil

/**
 * Data Transfer Object to represent the request parameters required to search
 * for occurrence records against biocache-service.
 *
 * @author "Nick dos Remedios <Nick.dosRemedios@csiro.au>"
 */
@Slf4j
@AutoClone
@EqualsAndHashCode
class SearchRequestParams implements Validateable{
    Long qId // "qid:12312321"
    String formattedQuery
    String q = ""
    String[] fq = []; // must not be null
    String fl = ""
    /** The facets to be included by the search Initialised with the default facets to use */
    String[] facets = [] // get from http://biocache.ala.org.au/ws/search/facets (and cache) // FacetThemes.allFacets;
    /** The limit for the number of facets to return */
    Integer flimit = 10
    /** The sort order in which to return the facets.  Either count or index.  When empty string the default values are used as defined in the Theme based facets */
    String fsort = ""
    /** The offset of facets to return.  Used in conjunction to flimit */
    Integer foffset = 0
    /** The prefix to limit facet values*/
    String fprefix = ""
    /**  pagination params */
    Integer start = 0
    Integer offset // grails version of start
    Integer pageSize = 20
    Integer max // grails version of pageSize
    String sort = "first_loaded_date"
    String dir = "desc"
    String order // grails version of dir
    String displayString
    /**  The query context to be used for the search.  This will be used to generate extra query filters based on the search technology */
    String qc = Holders.config.getProperty('biocache.queryContext', String, '')
    /** To disable facets */
    Boolean facet = true

    /** The quality profile to use, null for default */
    String qualityProfile
    /** If to disable all default filters*/
    boolean disableAllQualityFilters = false
    /** Default filters to disable (currently can only disable on category, so it's a list of disabled category name)*/
    List<String> disableQualityFilter = []

    /**
     * Custom toString method to produce a String to be used as the request parameters
     * for the Biocache Service webservices
     *
     * @return request parameters string
     */
    @Override
    public String toString() {
        return toString(false);
    }

    /**
     * Produce a URI encoded query string for use in java.util.URI, etc
     *
     * @return encoded query string
     */
    public String getEncodedParams() {
        return toString(true);
    }

    /**
     * Common code to output a param string with conditional encoding of values
     *
     * @param encodeParams
     * @return query string
     */
    public String toString(Boolean encodeParams) {
        StringBuilder req = new StringBuilder();
        req.append("q=").append(conditionalEncode(q, encodeParams));
        fq.each { filter ->
            req.append("&fq=").append(conditionalEncode(filter, encodeParams))
        }

        if (disableAllQualityFilters) {
            req.append("&disableAllQualityFilters=true")
        }

        if (qualityProfile) {
            req.append("&qualityProfile=").append(conditionalEncode(qualityProfile, encodeParams))
        }

        disableQualityFilter.each { dqf ->
            req.append("&disableQualityFilter=").append(conditionalEncode(dqf, encodeParams))
        }

        req.append("&start=").append(offset?:start);
        req.append("&pageSize=").append(max?:(pageSize>0)?pageSize:20) // fix for #337 (revert if fieldguides is fixed)
        req.append("&sort=").append(sort);
        req.append("&dir=").append(order?:dir);
        req.append("&qc=").append(conditionalEncode(qc, encodeParams));

        if (facet && facets?.length > 0) {
            String facetsListString = facets.join(",")
            req.append("&facets=").append(conditionalEncode(facetsListString, encodeParams))
        }
        
        if (flimit != 30)
            req.append("&flimit=").append(flimit);
        if (fl.length() > 0)
            req.append("&fl=").append(conditionalEncode(fl, encodeParams));
        if(formattedQuery)
            req.append("&formattedQuery=").append(conditionalEncode(formattedQuery, encodeParams));
        if(!facet)
            req.append("&facet=false");
        if(!"".equals(fsort))
            req.append("&fsort=").append(fsort);
        if(foffset > 0)
            req.append("&foffset=").append(foffset);
        if(!"".equals(fprefix))
            req.append("&fprefix=").append(fprefix);

        return req.toString();
    }

    /**
     * URI encode the param value if isEncoded is true
     *
     * @param input
     * @param isEncoded
     * @return query string
     */
    public String conditionalEncode(String input, Boolean isEncoded) {
        String output;
        
        if (input == null) {
            output = "";
        } else if (isEncoded) {
            try {
                output = URIUtil.encodeWithinQuery(input);
            } catch (URIException e) {
                logger.warn("URIUtil encoding error: " + e.getMessage(), e);
                output = input;
            }
        } else {
            output = input;
        }

        return output;
    }

    /**
     * Constructs the params to be returned in the result
     * @return req
     */
    String getUrlParams(){
        StringBuilder req = new StringBuilder();
        if(qId != null){
            req.append("?q=qid:").append(qId);
        } else if(q) {
            try{
                req.append("?q=").append(URLEncoder.encode(q, "UTF-8"));
            } catch(UnsupportedEncodingException e){}
        }

        for(String f : fq){
            //only add the fq if it is not the query context
            if(f.length()>0 && !f.equals(qc))
                try{
                    req.append("&fq=").append(URLEncoder.encode(f, "UTF-8"));
                } catch(UnsupportedEncodingException e){}
        }

        if(qc){
            req.append("&qc=").append(URLEncoder.encode(qc, "UTF-8"));
        }

        if (disableAllQualityFilters) {
            req.append("&disableAllQualityFilters=true")
        }

        if (qualityProfile) {
            req.append("&qualityProfile=").append(URLEncoder.encode(qualityProfile, "UTF-8"))
        }

        disableQualityFilter.each { dqf ->
            req.append("&disableQualityFilter=").append(URLEncoder.encode(dqf, "UTF-8"))
        }
        return req.toString();
    }
}
